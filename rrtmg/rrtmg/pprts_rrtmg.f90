!-------------------------------------------------------------------------
! This file is part of the TenStream solver.
!
! This program is free software: you can redistribute it and/or modify
! it under the terms of the GNU General Public License as published by
! the Free Software Foundation, either version 3 of the License, or
! (at your option) any later version.
!
! This program is distributed in the hope that it will be useful,
! but WITHOUT ANY WARRANTY; without even the implied warranty of
! MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
! GNU General Public License for more details.
!
! You should have received a copy of the GNU General Public License
! along with this program.  If not, see <http://www.gnu.org/licenses/>.
!
! Copyright (C) 2010-2015  Fabian Jakub, <fabian@jakub.com>
!-------------------------------------------------------------------------

!> \page Routines to call tenstream with optical properties from RRTM
!! The function `tenstream_rrtmg` provides an easy interface to
!! couple the TenStream solvers to a host model.
!!
!! * Tasks that have to be performed:
!!   - Radiative transfer needs to read a background profile that goes up till Top of the Atmosphere
!!   - Interpolate or merge the provided dynamics grid variables onto the the background profile
!!   - Compute optical properties with RRTMG
!!   - Solve the radiative transfer equation
!!   - And will return the fluxes on layer interfaces as well as the mean absorption in the layers
!!
!! Please carefully study the input and output parameters of subroutine ``tenstream_rrtmg()``
!!
!!

module m_pprts_rrtmg
  use, intrinsic :: iso_c_binding

#include "petsc/finclude/petsc.h"
  use petsc

  use mpi, only : mpi_comm_rank
  use m_tenstr_parkind_sw, only: im => kind_im, rb => kind_rb
  use m_data_parameters, only : init_mpi_data_parameters, &
      iintegers, ireals, zero, one, i0, i1, i2, i9,         &
      mpiint, pi, default_str_len
  use m_pprts_base, only : t_solver
  use m_pprts, only : init_pprts, set_angles, set_optical_properties, solve_pprts, destroy_pprts,&
      pprts_get_result, pprts_get_result_toZero
  use m_adaptive_spectral_integration, only: need_new_solution
  use m_helper_functions, only : read_ascii_file_2d, gradient, meanvec, imp_bcast, &
      imp_allreduce_min, imp_allreduce_max, imp_allreduce_mean, &
      search_sorted_bisection, CHKERR, deg2rad, &
      reverse, approx, itoa
  use m_petsc_helpers, only: dmda_convolve_ediff_srfc

  use m_netcdfIO, only : ncwrite

  use m_dyn_atm_to_rrtmg, only: t_tenstr_atm, plkint, print_tenstr_atm, vert_integral_coeff

  use m_optprop_rrtmg, only: optprop_rrtm_lw, optprop_rrtm_sw

  implicit none

  private
  public :: pprts_rrtmg, destroy_pprts_rrtmg

!  logical,parameter :: ldebug=.True.
  logical,parameter :: ldebug=.False.

contains

  subroutine init_pprts_rrtmg(comm, solver, dx, dy, dz, &
                  phi0, theta0, &
                  xm, ym, zm, nxproc, nyproc)

    integer(mpiint), intent(in) :: comm

    real(ireals), intent(in)      :: dx, dy, phi0, theta0, dz(:,:,:)
    integer(iintegers),intent(in) :: xm, ym, zm
    class(t_solver),intent(inout) :: solver

    ! arrays containing xm and ym for all nodes :: dim[x-ranks, y-ranks]
    integer(iintegers),intent(in), optional :: nxproc(:), nyproc(:)

    if(present(nxproc) .neqv. present(nyproc)) then
      print *,'Wrong call to init_tenstream_rrtm_lw --    &
            & in order to work, we need both arrays for &
            & the domain decomposition, call with nxproc AND nyproc'
      call CHKERR(1_mpiint, 'init_tenstream_rrtm_lw -- missing arguments nxproc or nyproc')
    endif
    if(present(nxproc) .and. present(nyproc)) then
      call init_pprts(comm, zm, xm, ym, dx,dy,phi0, theta0, solver, nxproc=nxproc, nyproc=nyproc, dz3d=dz)
    else ! we let petsc decide where to put stuff
      call init_pprts(comm, zm, xm, ym, dx, dy, phi0, theta0, solver, dz3d=dz)
    endif

  end subroutine

  subroutine smooth_surface_fluxes(solver, edn, eup)
    class(t_solver), intent(inout)  :: solver                       ! solver type (e.g. t_solver_8_10)
    real(ireals),allocatable, dimension(:,:,:), intent(inout) :: edn, eup  ! [nlyr+1, local_nx, local_ny ]
    integer(iintegers) :: i, kernel_width, Niter
    real(ireals) :: radius, mflx_up, mflx_dn
    logical :: lflg
    integer(mpiint) :: myid, ierr

    call mpi_comm_rank(solver%comm, myid, ierr); call CHKERR(ierr)

    call PetscOptionsGetReal(PETSC_NULL_OPTIONS, PETSC_NULL_CHARACTER , &
      "-pprts_smooth_srfc_flx", radius , lflg , ierr) ;call CHKERR(ierr)

    if(.not.lflg) return

    if(approx(radius, -one)) then
      call imp_allreduce_mean(solver%comm,  edn(ubound(edn,1),:,:), mflx_dn); edn(ubound(edn,1),:,:) = mflx_dn
      call imp_allreduce_mean(solver%comm,  eup(ubound(eup,1),:,:), mflx_up); eup(ubound(eup,1),:,:) = mflx_up
      if(ldebug.and.myid.eq.0) &
        print *,'Smoothing diffuse srfc fluxes over the entire domain mean downward flx', mflx_dn, 'up', mflx_up
      return
    endif

    call find_iter_and_kernelwidth(Niter, kernel_width)
    do i = 1, Niter
      call dmda_convolve_ediff_srfc(solver%C_diff%da, kernel_width, edn(ubound(edn,1):ubound(edn,1),:,:))
      call dmda_convolve_ediff_srfc(solver%C_diff%da, kernel_width, eup(ubound(eup,1):ubound(eup,1),:,:))
    enddo
    contains
      subroutine find_iter_and_kernelwidth(Niter, kernel_width)
        integer(iintegers), intent(out) :: kernel_width, Niter
        integer(iintegers), parameter :: test_Ni=10
        integer(iintegers) :: i, min_iter
        real(ireals) :: test_k(test_Ni), residuals(test_Ni)
        real(ireals) :: radius_in_pixel

        radius_in_pixel = radius / ((solver%atm%dx+solver%atm%dy)/2)
        ! Try a couple of number of iterations and determine optimal kernel_width
        min_iter = 1
        do i = 1, test_Ni
          test_k(i) = (sqrt( (12*radius_in_pixel**2 + i)/i +1 ) -1 )/2
          if(nint(test_k(i)).ge.min(solver%C_diff%xm,solver%C_diff%ym)) min_iter = i+1
        enddo
        if(min_iter.gt.test_Ni) &
          call CHKERR(int(min_iter, mpiint), 'the smoothing iteration count would be larger than '// &
            itoa(min_iter)//'... this would be really expensive, you can set the value higher but I'// &
            'suspect that you are trying something weird')
        ! We want it
        ! as close as possible to an integer
        ! and as big as possible
        ! but not bigger than the local domain size
        ! or a certain max value
        residuals = abs(test_k - nint(test_k))

        Niter = min_iter -1 + minloc(residuals(min_iter:test_Ni),dim=1)
        kernel_width = nint(test_k(Niter))

        call imp_allreduce_max(solver%comm, Niter, i); Niter = i
        call imp_allreduce_min(solver%comm, kernel_width, i); kernel_width = i

        if(kernel_width.eq.0) Niter=0

        if(ldebug.and.myid.eq.0) then
          do i = 1, test_Ni
          print *, 'iter', i, 'test_k', test_k(i), residuals(i)
          enddo
          print *,'Smoothing diffuse srfc fluxes with radius', solver%atm%dx, radius, radius_in_pixel, 'Niter', Niter, 'kwidth', kernel_width
        endif

      end subroutine
  end subroutine

  subroutine pprts_rrtmg(comm, solver, atm, ie, je, &
      dx, dy, phi0, theta0, &
      albedo_thermal, albedo_solar,                   &
      lthermal, lsolar,                               &
      edir,edn,eup,abso,                              &
      nxproc, nyproc, icollapse,                      &
      opt_time, solar_albedo_2d, thermal_albedo_2d,   &
      phi2d, theta2d,                                 &
      opt_solar_constant)

    integer(mpiint), intent(in)     :: comm ! MPI Communicator

    class(t_solver), intent(inout)  :: solver                       ! solver type (e.g. t_solver_8_10)
    type(t_tenstr_atm), intent(in)  :: atm                          ! contains info on atmospheric constituents
    integer(iintegers), intent(in)  :: ie, je                       ! local domain size in x and y direction
    real(ireals), intent(in)        :: dx, dy                       ! horizontal grid spacing in [m]
    real(ireals), intent(in)        :: phi0, theta0                 ! Sun's angles, azimuth phi(0=North, 90=East), zenith(0 high sun, 80=low sun)
    real(ireals), intent(in)        :: albedo_solar, albedo_thermal ! broadband ground albedo for solar and thermal spectrum

    ! Compute solar or thermal radiative transfer. Or compute both at once.
    logical, intent(in) :: lsolar, lthermal

    ! nxproc dimension of nxproc is number of ranks along x-axis, and entries in nxproc are the size of local Nx
    ! nyproc dimension of nyproc is number of ranks along y-axis, and entries in nyproc are the number of local Ny
    ! if not present, we let petsc decide how to decompose the fields(probably does not fit the decomposition of a host model)
    integer(iintegers),intent(in),optional :: nxproc(:), nyproc(:)

    integer(iintegers),intent(in),optional :: icollapse ! experimental, dont use it if you dont know what you are doing.

    ! opt_time is the model time in seconds. If provided we will track the error growth of the solutions
    ! and compute new solutions only after threshold estimate is exceeded.
    ! If solar_albedo_2d is present, we use a 2D surface albedo
    real(ireals), optional, intent(in) :: opt_time, solar_albedo_2d(:,:), thermal_albedo_2d(:,:), opt_solar_constant

    real(ireals), optional, intent(in) :: phi2d(:,:), theta2d(:,:)

    ! Fluxes and absorption in [W/m2] and [W/m3] respectively.
    ! Dimensions will probably be bigger than the dynamics grid, i.e. will have
    ! the size of the merged grid. If you only want to use heating rates on the
    ! dynamics grid, use the lower layers, i.e.,
    !   edn(ubound(edn,1)-nlay_dynamics : ubound(edn,1) )
    ! or:
    !   abso(ubound(abso,1)-nlay_dynamics+1 : ubound(abso,1) )
    real(ireals),allocatable, dimension(:,:,:), intent(inout) :: edir, edn, eup  ! [nlyr+1, local_nx, local_ny ]
    real(ireals),allocatable, dimension(:,:,:), intent(inout) :: abso            ! [nlyr  , local_nx, local_ny ]

    ! ---------- end of API ----------------

    ! Counters
    integer(iintegers) :: i, j, icol
    integer(iintegers) :: ke, ke1

    ! vertical thickness in [m]
    real(ireals),allocatable :: dz_t2b(:,:,:) ! dz (t2b := top 2 bottom)

    ! for debug purposes, can output variables into netcdf files
    !character(default_str_len) :: output_path(2) ! [ filename, varname ]
    !logical :: lfile_exists

    integer(mpiint) :: myid, ierr
    logical :: lrrtmg_only, lskip_thermal, lflg

    if(present(icollapse)) call CHKERR(1_mpiint, 'Icollapse currently not tested. Dont Use it')

    call mpi_comm_rank(comm, myid, ierr); call CHKERR(ierr)

    ke1 = ubound(atm%plev,1)
    ke = ubound(atm%tlay,1)

    allocate(dz_t2b(ke, ie, je))
    do j=i1,je
      do i=i1,ie
        icol =  i+(j-1)*ie
        dz_t2b(:,i,j) = reverse(atm%dz(:,icol))
      enddo
    enddo

    if(ldebug .and. myid.eq.0) then
      call print_tenstr_atm(atm)
    endif

    if(.not.solver%linitialized) then
      call init_pprts_rrtmg(comm, solver, dx, dy, dz_t2b, phi0, theta0, &
        ie,je,ke, nxproc, nyproc)
    endif
    call PetscOptionsGetBool(PETSC_NULL_OPTIONS, PETSC_NULL_CHARACTER , &
      "-rrtmg_only" , lrrtmg_only , lflg , ierr) ;call CHKERR(ierr)
    if(.not.lflg) lrrtmg_only=.False. ! by default use normal tenstream solver

    ! Allocate space for results -- for integrated values...
    if(.not.allocated(edn )) allocate(edn (solver%C_one1%zm, solver%C_one1%xm, solver%C_one1%ym))
    if(.not.allocated(eup )) allocate(eup (solver%C_one1%zm, solver%C_one1%xm, solver%C_one1%ym))
    if(.not.allocated(abso)) allocate(abso(solver%C_one%zm , solver%C_one%xm , solver%C_one%ym ))
    edn = zero
    eup = zero
    abso= zero

    lskip_thermal = .False.
    call PetscOptionsGetBool(PETSC_NULL_OPTIONS, PETSC_NULL_CHARACTER , &
      "-skip_thermal" , lskip_thermal, lflg , ierr) ;call CHKERR(ierr)
    if(lthermal.and..not.lskip_thermal)then
      call compute_thermal(solver, atm, ie, je, ke, ke1, &
        albedo_thermal, &
        edn, eup, abso, opt_time=opt_time, lrrtmg_only=lrrtmg_only, &
        thermal_albedo_2d=thermal_albedo_2d)
    endif

    if(lsolar) then
      if(.not.allocated(edir)) allocate(edir (solver%C_one1%zm, solver%C_one1%xm, solver%C_one1%ym))
      edir = zero
      call compute_solar(solver, atm, ie, je, ke, &
        phi0, theta0, albedo_solar, &
        edir, edn, eup, abso, opt_time=opt_time, solar_albedo_2d=solar_albedo_2d, &
        lrrtmg_only=lrrtmg_only, phi2d=phi2d, theta2d=theta2d, opt_solar_constant=opt_solar_constant)
    endif

    call smooth_surface_fluxes(solver, edn, eup)

    !if(myid.eq.0 .and. ldebug) then
    !  if(present(opt_time)) then
    !    write (output_path(1), "(A,I6.6,L1,L1,A3)") "3dout_",int(opt_time),lthermal,lsolar, '.nc'
    !  else
    !    write (output_path(1), "(A,L1,L1,A3)") "3dout_",lthermal,lsolar, '.nc'
    !  endif
    !  inquire( file=trim(output_path(1)), exist=lfile_exists )
    !  if(.not. lfile_exists) then
    !    output_path(2) = 'edir' ; call ncwrite(output_path, edir, i)
    !    output_path(2) = 'edn'  ; call ncwrite(output_path, edn , i)
    !    output_path(2) = 'eup'  ; call ncwrite(output_path, eup , i)
    !    output_path(2) = 'abso' ; call ncwrite(output_path, abso, i)
    !    if(present(d_lwc)) then
    !      output_path(2) = 'lwc'  ; call ncwrite(output_path, d_lwc, i)
    !    endif
    !    if(present(d_iwc)) then
    !      output_path(2) = 'iwc'  ; call ncwrite(output_path, d_iwc, i)
    !    endif
    !  endif
    !endif
  end subroutine

  subroutine compute_thermal(solver, atm, ie, je, ke, ke1, &
      albedo, &
      edn, eup, abso, opt_time, lrrtmg_only, &
      thermal_albedo_2d)

    use m_tenstr_rrlw_wvn, only : ngb, wavenum1, wavenum2
    use m_tenstr_parrrtm, only: ngptlw, nbndlw

    class(t_solver),    intent(inout) :: solver
    type(t_tenstr_atm), intent(in), target :: atm
    integer(iintegers), intent(in)    :: ie, je, ke,ke1

    real(ireals),intent(in) :: albedo

    real(ireals),intent(inout),dimension(:,:,:) :: edn, eup, abso

    real(ireals), optional, intent(in) :: opt_time, thermal_albedo_2d(:,:)
    logical, optional, intent(in) :: lrrtmg_only

    real(ireals),allocatable, target, dimension(:,:,:,:) :: tau, Bfrac  ! [nlyr, ie, je, ngptlw]
    real(ireals),allocatable, dimension(:,:,:) :: kabs, ksca, g, Blev   ! [nlyr(+1), local_nx, local_ny]
    real(ireals),allocatable, dimension(:,:,:), target :: spec_edn,spec_eup,spec_abso  ! [nlyr(+1), local_nx, local_ny ]
    real(ireals),allocatable, dimension(:) :: integral_coeff            ! [nlyr]

    real(ireals), allocatable, dimension(:,:,:) :: ptau, pBfrac
    real(ireals), pointer, dimension(:,:,:) :: patm_dz
    real(ireals), pointer, dimension(:,:) :: pedn, peup, pabso

    integer(iintegers) :: i, j, k, icol, ib, current_ibnd
    logical :: need_any_new_solution

    integer(mpiint) :: myid, ierr

    call mpi_comm_rank(solver%comm, myid, ierr); call CHKERR(ierr)

    allocate(spec_edn (solver%C_one1%zm, solver%C_one1%xm, solver%C_one1%ym))
    allocate(spec_eup (solver%C_one1%zm, solver%C_one1%xm, solver%C_one1%ym))
    allocate(spec_abso(solver%C_one%zm , solver%C_one%xm , solver%C_one%ym ))

    need_any_new_solution=.False.
    do ib=1,ngptlw
      if(need_new_solution(solver%comm, solver%solutions(500+ib), opt_time, solver%lenable_solutions_err_estimates)) &
        need_any_new_solution=.True.
    enddo
    if(.not.need_any_new_solution) then
      do ib=1,ngptlw
        call pprts_get_result(solver, spec_edn, spec_eup, spec_abso, opt_solution_uid=500+ib)
        edn  = edn  + spec_edn
        eup  = eup  + spec_eup
        abso = abso + spec_abso
      enddo
      return
    endif

    ! Compute optical properties with RRTMG
    allocate(tau  (ke, i1:ie, i1:je, ngptlw))
    allocate(Bfrac(ke1, i1:ie, i1:je, ngptlw))
    allocate(ptau  (ke, i1, ngptlw))
    allocate(pBfrac(ke, i1, ngptlw))
    allocate(integral_coeff(ke))

    if(lrrtmg_only) then
      do j=i1,je
        do i=i1,ie
          icol =  i+(j-1)*ie

          pedn (1:ke1, 1:1) => spec_edn (:,i,j)
          peup (1:ke1, 1:1) => spec_eup (:,i,j)
          pabso(1:ke , 1:1) => spec_abso(:,i,j)

          do k=1,ke
            integral_coeff(k) = vert_integral_coeff(atm%plev(k,icol), atm%plev(k+1,icol))
          enddo

          if (present(thermal_albedo_2d)) then
            call optprop_rrtm_lw(i1, ke, thermal_albedo_2d(i,j),      &
              atm%plev(:,icol), atm%tlev(:, icol), atm%tlay(:, icol),           &
              atm%h2o_lay(:, icol), atm%o3_lay(:, icol) , atm%co2_lay(:, icol),     &
              atm%ch4_lay(:, icol), atm%n2o_lay(:, icol), atm%o2_lay(:, icol) ,     &
              atm%lwc(:,icol)*integral_coeff, atm%reliq(:, icol), &
              atm%iwc(:,icol)*integral_coeff, atm%reice(:, icol), &
              ptau, pBfrac, peup, pedn, pabso)
          else
            call optprop_rrtm_lw(i1, ke, albedo,      &
              atm%plev(:,icol), atm%tlev(:, icol), atm%tlay(:, icol),           &
              atm%h2o_lay(:, icol), atm%o3_lay(:, icol) , atm%co2_lay(:, icol),     &
              atm%ch4_lay(:, icol), atm%n2o_lay(:, icol), atm%o2_lay(:, icol) ,     &
              atm%lwc(:,icol)*integral_coeff, atm%reliq(:, icol), &
              atm%iwc(:,icol)*integral_coeff, atm%reice(:, icol), &
              ptau, pBfrac, peup, pedn, pabso)
          endif

          tau  (:,i,j,:) = ptau(:,i1,:)
          Bfrac(2:ke1,i,j,:) = pBfrac(:,i1,:)

          eup(:,i,j)  = eup(:,i,j)  + reverse(spec_eup (:,i,j))
          edn(:,i,j)  = edn(:,i,j)  + reverse(spec_edn (:,i,j))
          abso(:,i,j) = abso(:,i,j) + reverse( &
            (spec_edn(2:ke1,i,j)-spec_edn(1:ke,i,j)+spec_eup(1:ke,i,j)-spec_eup(2:ke1,i,j)) / &
             atm%dz(:,icol))

        enddo
      enddo
      return
    else
      do j=i1,je
        do i=i1,ie
          icol =  i+(j-1)*ie
          do k=1,ke
            integral_coeff(k) = vert_integral_coeff(atm%plev(k,icol), atm%plev(k+1,icol))
          enddo
          if (present(thermal_albedo_2d)) then
            call optprop_rrtm_lw(i1, ke, thermal_albedo_2d(i,j), &
              atm%plev(:,icol), atm%tlev(:, icol), atm%tlay(:, icol),           &
              atm%h2o_lay(:, icol), atm%o3_lay(:, icol) , atm%co2_lay(:, icol),     &
              atm%ch4_lay(:, icol), atm%n2o_lay(:, icol), atm%o2_lay(:, icol) ,     &
              atm%lwc(:, icol)*integral_coeff, atm%reliq(:, icol), &
              atm%iwc(:, icol)*integral_coeff, atm%reice(:, icol), &
              tau=ptau, Bfrac=pBfrac)
          else
            call optprop_rrtm_lw(i1, ke, albedo, &
              atm%plev(:,icol), atm%tlev(:, icol), atm%tlay(:, icol),           &
              atm%h2o_lay(:, icol), atm%o3_lay(:, icol) , atm%co2_lay(:, icol),     &
              atm%ch4_lay(:, icol), atm%n2o_lay(:, icol), atm%o2_lay(:, icol) ,     &
              atm%lwc(:, icol)*integral_coeff, atm%reliq(:, icol), &
              atm%iwc(:, icol)*integral_coeff, atm%reice(:, icol), &
              tau=ptau, Bfrac=pBfrac)
          endif
          tau  (:,i,j,:) = ptau(:,i1,:)
          Bfrac(2:ke1,i,j,:) = pBfrac(:,i1,:)
        enddo
      enddo
    endif
    Bfrac(1,:,:,:) = Bfrac(2,:,:,:)

    allocate(kabs (ke , i1:ie, i1:je))
    allocate(Blev (ke1, i1:ie, i1:je))

    ! rrtmg_lw does not support thermal scattering... set to zero
    allocate(ksca (ke , i1:ie, i1:je), source=zero)
    allocate(g    (ke , i1:ie, i1:je), source=zero)

    current_ibnd = -1 ! current lw band
    do ib = 1, ngptlw ! spectral integration
      if(need_new_solution(solver%comm, solver%solutions(500+ib), opt_time, solver%lenable_solutions_err_estimates)) then
        ! divide by thickness to convert from tau to coefficients per meter
        patm_dz(1:ke, i1:ie, i1:je) => atm%dz
        kabs = max(zero, tau(:,:,:,ib)) / patm_dz
        kabs = reverse(kabs)

        !Compute Plank Emission for nbndlw
        if(current_ibnd.eq.ngb(ib)) then ! still the same band, dont need to upgrade the plank emission
          continue
        else
          do j=i1,je
            do i=i1,ie
              icol = i+(j-1)*ie
              do k=i1,ke
                Blev(k+1,i,j) = plkint(real(wavenum1(ngb(ib))), real(wavenum2(ngb(ib))), real(atm%tlay(k, icol)))
              enddo
              Blev(1,i,j) = plkint(real(wavenum1(ngb(ib))), real(wavenum2(ngb(ib))), real(atm%tlev(1, icol)))
            enddo ! i
          enddo ! j
          current_ibnd = ngb(ib)

          if(ldebug)then
            if(any(Blev.lt.zero)) then
              print *,'Min Max Planck:', minval(Blev), maxval(Blev), 'location min', minloc(Blev)
              call CHKERR(1_mpiint, 'Found a negative Planck emission, this is not physical! Aborting...')
            endif
          endif
        endif

        call set_optical_properties(solver, albedo, kabs, ksca, g, reverse(Blev*Bfrac(:,:,:,ib)), &
            local_albedo_2d=thermal_albedo_2d, ldelta_scaling=.False.)
        call solve_pprts(solver, zero, opt_solution_uid=500+ib, opt_solution_time=opt_time)
      endif

      call pprts_get_result(solver, spec_edn, spec_eup, spec_abso, opt_solution_uid=500+ib)

      edn  = edn  + spec_edn
      eup  = eup  + spec_eup
      abso = abso + spec_abso

    enddo ! ib 1 -> nbndlw , i.e. spectral integration
  end subroutine compute_thermal

  subroutine compute_solar(solver, atm, ie, je, ke, &
      phi0, theta0, albedo, &
      edir, edn, eup, abso, opt_time, solar_albedo_2d, lrrtmg_only, &
      phi2d, theta2d, opt_solar_constant)

      use m_tenstr_parrrsw, only: ngptsw
      use m_tenstr_rrtmg_sw_spcvrt, only: tenstr_solsrc

    class(t_solver), intent(inout)  :: solver
    type(t_tenstr_atm), intent(in), target :: atm
    integer(iintegers),intent(in)   :: ie, je, ke

    real(ireals),intent(in) :: albedo
    real(ireals),intent(in) :: phi0, theta0
    real(ireals),intent(in),dimension(:,:),optional :: phi2d, theta2d

    real(ireals),intent(inout),dimension(:,:,:) :: edir, edn, eup, abso

    real(ireals), optional, intent(in) :: opt_time, solar_albedo_2d(:,:)
    logical, optional, intent(in) :: lrrtmg_only
    real(ireals), intent(in), optional :: opt_solar_constant

    real(ireals) :: edirTOA

    real(ireals),allocatable, dimension(:,:,:,:) :: tau, w0, g          ! [nlyr, ie, je, ngptsw]
    real(ireals),allocatable, dimension(:,:,:)   :: kabs, ksca, kg      ! [nlyr, local_nx, local_ny]
    real(ireals),allocatable, dimension(:,:,:), target   :: spec_edir,spec_abso ! [nlyr(+1), local_nx, local_ny ]
    real(ireals),allocatable, dimension(:,:,:), target   :: spec_edn, spec_eup  ! [nlyr(+1), local_nx, local_ny ]
    real(ireals),allocatable, dimension(:) :: integral_coeff            ! [nlyr]

    real(ireals), allocatable, dimension(:,:,:) :: ptau, pw0, pg
    real(ireals), pointer, dimension(:,:,:) :: patm_dz
    real(ireals), pointer, dimension(:,:) :: pedn, peup, pabso

    real(ireals) :: col_theta, col_albedo

    integer(iintegers) :: i, j, k, icol, ib
    logical :: need_any_new_solution

    allocate(spec_edir(solver%C_one1%zm, solver%C_one1%xm, solver%C_one1%ym))
    allocate(spec_edn (solver%C_one1%zm, solver%C_one1%xm, solver%C_one1%ym))
    allocate(spec_eup (solver%C_one1%zm, solver%C_one1%xm, solver%C_one1%ym))
    allocate(spec_abso(solver%C_one%zm , solver%C_one%xm , solver%C_one%ym ))

    need_any_new_solution=.False.
    do ib=1,ngptsw
      if(need_new_solution(solver%comm, solver%solutions(ib), opt_time, solver%lenable_solutions_err_estimates)) &
        need_any_new_solution=.True.
    enddo
    if(.not.need_any_new_solution) then
      do ib=1,ngptsw
        call pprts_get_result(solver, spec_edn, spec_eup, spec_abso, spec_edir, opt_solution_uid=ib)
        edir = edir + spec_edir
        edn  = edn  + spec_edn
        eup  = eup  + spec_eup
        abso = abso + spec_abso
      enddo
      return
    endif

    ! Compute optical properties with RRTMG
    allocate(tau(ke, i1:ie, i1:je, ngptsw))
    allocate(w0 (ke, i1:ie, i1:je, ngptsw))
    allocate(g  (ke, i1:ie, i1:je, ngptsw))
    allocate(ptau(ke, i1, ngptsw))
    allocate(pw0 (ke, i1, ngptsw))
    allocate(pg  (ke, i1, ngptsw))

    allocate(integral_coeff(ke))

    if(present(theta2d).and.present(phi2d)) then
      call set_angles(solver, phi0, theta0, phi2d=phi2d, theta2d=theta2d)
    else
      call set_angles(solver, phi0, theta0)
    endif

    if(lrrtmg_only) then
      do j=1,je
        do i=1,ie
          icol =  i+(j-1)*ie

          pEdn (1:size(edn ,1), 1:1) => spec_edn (:,i,j)
          pEup (1:size(eup ,1), 1:1) => spec_eup (:,i,j)
          pabso(1:size(abso,1), 1:1) => spec_abso(:,i,j)

          do k=1,ke
            integral_coeff(k) = vert_integral_coeff(atm%plev(k,icol), atm%plev(k+1,icol))
          enddo

          if(present(theta2d)) then
            col_theta = theta2d(i,j)
          else
            col_theta = theta0
          endif

          if(present(solar_albedo_2d)) then
            col_albedo = solar_albedo_2d(i,j)
          else
            col_albedo = albedo
          endif
          call optprop_rrtm_sw(i1, ke, &
            col_theta, col_albedo, &
            atm%plev(:,icol), atm%tlev(:,icol), atm%tlay(:,icol), &
            atm%h2o_lay(:,icol), atm%o3_lay(:,icol), atm%co2_lay(:,icol), &
            atm%ch4_lay(:,icol), atm%n2o_lay(:,icol), atm%o2_lay(:,icol), &
            atm%lwc(:,icol)*integral_coeff, atm%reliq(:,icol), &
            atm%iwc(:,icol)*integral_coeff, atm%reice(:,icol), &
            ptau, pw0, pg, &
            pEup, pEdn, pabso, &
            opt_solar_constant=opt_solar_constant)

          tau(:,i,j,:) = ptau(:,i1,:)
          w0 (:,i,j,:) = pw0(:,i1,:)
          g  (:,i,j,:) = pg(:,i1,:)

          edir(:,i,j) = edir(:,i,j) + zero
          eup (:,i,j) = eup (:,i,j) + reverse(spec_eup (:, i, j))
          edn (:,i,j) = edn (:,i,j) + reverse(spec_edn (:, i, j))
          abso(:,i,j) = abso(:,i,j) + reverse( &
            (spec_edn(2:ke+1,i,j)-spec_edn(1:ke,i,j)+spec_eup(1:ke,i,j)-spec_eup(2:ke+1,i,j)) / &
             atm%dz(:,icol))
        enddo
      enddo
      return
    else
      do j=1,je
        do i=1,ie
          icol =  i+(j-1)*ie
          do k=1,ke
            integral_coeff(k) = vert_integral_coeff(atm%plev(k,icol), atm%plev(k+1,icol))

          enddo

          if(present(theta2d)) then
            col_theta = theta2d(i,j)
          else
            col_theta = theta0
          endif

          if(present(solar_albedo_2d)) then
            col_albedo = solar_albedo_2d(i,j)
          else
            col_albedo = albedo
          endif

          call optprop_rrtm_sw(i1, ke, &
            col_theta, col_albedo, &
            atm%plev(:,icol), atm%tlev(:,icol), atm%tlay(:,icol), &
            atm%h2o_lay(:,icol), atm%o3_lay(:,icol), atm%co2_lay(:,icol), &
            atm%ch4_lay(:,icol), atm%n2o_lay(:,icol), atm%o2_lay(:,icol), &
            atm%lwc(:,icol)*integral_coeff, atm%reliq(:,icol), &
            atm%iwc(:,icol)*integral_coeff, atm%reice(:,icol), &
            ptau, pw0, pg, &
            opt_solar_constant=opt_solar_constant)

          tau(:,i,j,:) = ptau(:,i1,:)
          w0 (:,i,j,:) = pw0(:,i1,:)
          g  (:,i,j,:) = pg(:,i1,:)
        enddo
      enddo
    endif
    w0 = min(one, max(zero, w0))

    allocate(kabs(ke , i1:ie, i1:je))
    allocate(ksca(ke , i1:ie, i1:je))
    allocate(kg  (ke , i1:ie, i1:je))


    do ib=1,ngptsw

      if(need_new_solution(solver%comm, solver%solutions(ib), opt_time, solver%lenable_solutions_err_estimates)) then
        patm_dz(1:ke, i1:ie, i1:je) => atm%dz
        kabs = max(zero, tau(:,:,:,ib)) * (one - w0(:,:,:,ib))
        ksca = max(zero, tau(:,:,:,ib)) * w0(:,:,:,ib)
        kg   = min(one, max(zero, g(:,:,:,ib)))
        kabs = reverse(kabs / patm_dz)
        ksca = reverse(ksca / patm_dz)
        kg   = reverse(kg)

        if(present(opt_solar_constant)) then
          edirTOA = tenstr_solsrc(ib) /sum(tenstr_solsrc) * opt_solar_constant
        else
          edirTOA = tenstr_solsrc(ib)
        endif

        ! dont use delta scaling here because rrtmg values should already be delta scaled
        call set_optical_properties(solver, albedo, kabs, ksca, kg, local_albedo_2d=solar_albedo_2d, ldelta_scaling=.False.)
        call solve_pprts(solver, edirTOA, opt_solution_uid=ib, opt_solution_time=opt_time)

      endif
      call pprts_get_result(solver, spec_edn, spec_eup, spec_abso, spec_edir, opt_solution_uid=ib)

      edir = edir + spec_edir
      edn  = edn  + spec_edn
      eup  = eup  + spec_eup
      abso = abso + spec_abso

    enddo ! ib 1 -> nbndsw , i.e. spectral integration
  end subroutine compute_solar

  subroutine destroy_pprts_rrtmg(solver, lfinalizepetsc)
    class(t_solver)     :: solver
    logical, intent(in) :: lfinalizepetsc
    ! Tidy up the solver
    call destroy_pprts(solver, lfinalizepetsc=lfinalizepetsc)
  end subroutine
end module
