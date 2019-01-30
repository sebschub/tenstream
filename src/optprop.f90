!-------------------------------------------------------------------------
! This file is part of the tenstream solver.
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

module m_optprop

#ifdef _XLF
      use ieee_arithmetic
#define isnan ieee_is_nan
#endif

use m_optprop_parameters, only : ldebug_optprop, coeff_mode
use m_helper_functions, only : rmse, CHKERR, itoa, ftoa, approx, deg2rad, swap
use m_data_parameters, only: ireals,irealLUT,irealLUT,iintegers,one,zero,i0,i1,inil,mpiint
use m_optprop_LUT, only : t_optprop_LUT, t_optprop_LUT_1_2,t_optprop_LUT_3_6, t_optprop_LUT_3_10, &
  t_optprop_LUT_8_10, t_optprop_LUT_3_16, t_optprop_LUT_8_16, t_optprop_LUT_8_18, &
  t_optprop_LUT_wedge_5_8
use m_optprop_ANN, only : ANN_init, ANN_get_dir2dir, ANN_get_dir2diff, ANN_get_diff2diff
use m_boxmc_geometry, only : setup_default_unit_cube_geometry, setup_default_wedge_geometry
use m_eddington, only: eddington_coeff_zdun
use m_tenstream_options, only: twostr_ratio

use mpi!, only: MPI_Comm_rank,MPI_DOUBLE_PRECISION,MPI_INTEGER,MPI_Bcast

implicit none

private
public :: t_optprop, t_optprop_1_2, t_optprop_3_6, t_optprop_3_10, t_optprop_wedge_5_8, &
  t_optprop_8_10, t_optprop_3_16, t_optprop_8_16, t_optprop_8_18, &
  OPP_1D_RETCODE

type,abstract :: t_optprop
  logical :: optprop_debug=ldebug_optprop
  class(t_optprop_LUT), allocatable :: OPP_LUT
  contains
    procedure :: init
    procedure :: get_coeff
    procedure :: get_coeff_bmc
    procedure :: dir2dir_coeff_symmetry
    procedure :: dir2diff_coeff_symmetry
    procedure :: destroy
end type

type,extends(t_optprop) :: t_optprop_1_2
end type

type,extends(t_optprop) :: t_optprop_3_6
end type

type,extends(t_optprop) :: t_optprop_3_10
end type

type,extends(t_optprop) :: t_optprop_8_10
end type

type,extends(t_optprop) :: t_optprop_3_16
end type

type,extends(t_optprop) :: t_optprop_8_16
end type

type,extends(t_optprop) :: t_optprop_8_18
end type

type,extends(t_optprop) :: t_optprop_wedge_5_8
end type

integer(mpiint), parameter :: OPP_1D_RETCODE = -1_mpiint

contains

  subroutine init(OPP, comm)
      class(t_optprop), intent(inout) :: OPP
      integer(mpiint) ,intent(in) :: comm
      integer(mpiint) :: ierr

      select case (coeff_mode)
          case(i0) ! LookUpTable Mode
            select type(OPP)
              class is (t_optprop_1_2)
               if(.not.allocated(OPP%OPP_LUT) ) allocate(t_optprop_LUT_1_2::OPP%OPP_LUT)

              class is (t_optprop_3_6)
               if(.not.allocated(OPP%OPP_LUT) ) allocate(t_optprop_LUT_3_6::OPP%OPP_LUT)

              class is (t_optprop_3_10)
               if(.not.allocated(OPP%OPP_LUT) ) allocate(t_optprop_LUT_3_10::OPP%OPP_LUT)

              class is (t_optprop_8_10)
               if(.not.allocated(OPP%OPP_LUT) ) allocate(t_optprop_LUT_8_10::OPP%OPP_LUT)

              class is (t_optprop_3_16)
               if(.not.allocated(OPP%OPP_LUT) ) allocate(t_optprop_LUT_3_16::OPP%OPP_LUT)

              class is (t_optprop_8_16)
               if(.not.allocated(OPP%OPP_LUT) ) allocate(t_optprop_LUT_8_16::OPP%OPP_LUT)

              class is (t_optprop_8_18)
               if(.not.allocated(OPP%OPP_LUT) ) allocate(t_optprop_LUT_8_18::OPP%OPP_LUT)

              class is (t_optprop_wedge_5_8)
               if(.not.allocated(OPP%OPP_LUT) ) allocate(t_optprop_LUT_wedge_5_8::OPP%OPP_LUT)
              class default
                stop ' init optprop : unexpected type for optprop object!'
            end select
            call OPP%OPP_LUT%init(comm)

          case(i1) ! ANN
            call ANN_init(comm, ierr)
  !          stop 'ANN not yet implemented'
          case default
            stop 'coeff mode optprop initialization not defined '
        end select
  end subroutine
  subroutine destroy(OPP)
      class(t_optprop) :: OPP
      if(allocated(OPP%OPP_LUT)) then
          call OPP%OPP_LUT%destroy()
          deallocate(OPP%OPP_LUT)
      endif
  end subroutine

  subroutine get_coeff(OPP, tauz, w0, g, aspect_zx, dir, C, ierr, angles, lswitch_east, lswitch_north, wedge_coords)
        class(t_optprop)                    :: OPP
        logical,intent(in)                  :: dir
        real(irealLUT),intent(in)           :: tauz, w0, g, aspect_zx
        real(irealLUT),intent(in),optional  :: angles(:)             ! phi and azimuth in degree
        logical,intent(in),optional         :: lswitch_east, lswitch_north
        real(irealLUT),intent(in),optional  :: wedge_coords(:)       ! 6 coordinates of wedge triangle, only used for wedge OPP types
        real(irealLUT),intent(out) :: C(:)
        integer(mpiint), intent(out) :: ierr

        ierr = 0

        select type (OPP)
        class is (t_optprop_1_2)
          call boxmc_lut_call(OPP, tauz, w0, g, aspect_zx, dir, C, angles, lswitch_east, lswitch_north)

        class is (t_optprop_3_6)
          call boxmc_lut_call(OPP, tauz, w0, g, aspect_zx, dir, C, angles, lswitch_east, lswitch_north)

        class is (t_optprop_3_10)
          call boxmc_lut_call(OPP, tauz, w0, g, aspect_zx, dir, C, angles, lswitch_east, lswitch_north)

        class is (t_optprop_8_10)
          call boxmc_lut_call(OPP, tauz, w0, g, aspect_zx, dir, C, angles, lswitch_east, lswitch_north)

        class is (t_optprop_3_16)
          call boxmc_lut_call(OPP, tauz, w0, g, aspect_zx, dir, C, angles, lswitch_east, lswitch_north)

        class is (t_optprop_8_16)
          call boxmc_lut_call(OPP, tauz, w0, g, aspect_zx, dir, C, angles, lswitch_east, lswitch_north)

        class is (t_optprop_8_18)
          call boxmc_lut_call(OPP, tauz, w0, g, aspect_zx, dir, C, angles, lswitch_east, lswitch_north)

        class is (t_optprop_wedge_5_8)
          call wedge_lut_call(OPP, tauz, w0, g, aspect_zx, dir, C, ierr, angles, wedge_coords)

        class default
          call CHKERR(1_mpiint, 'initialize LUT: unexpected type for optprop object!')
      end select
  end subroutine

  subroutine wedge_lut_call(OPP, tauz, w0, g, aspect_zx, ldir, C, ierr, in_angles, wedge_coords)
    class(t_optprop)                  :: OPP
    logical,intent(in)                :: ldir
    real(irealLUT),intent(in)           :: tauz, w0, g, aspect_zx
    real(irealLUT),intent(in),optional  :: in_angles(:)
    real(irealLUT),intent(in),optional  :: wedge_coords(:) ! 6 coordinates of wedge triangle, only used for wedge OPP types, have to be in local coords already (i.e. A=[0,0], B=[0,1], C=[...])
    real(irealLUT),intent(out)          :: C(:)
    integer(mpiint), intent(out) :: ierr

    logical,parameter :: compute_coeff_online=.False.
    real(ireals), allocatable :: vertices(:)

    ierr = 0

    if(compute_coeff_online) then
      if(.not.present(wedge_coords)) &
        call CHKERR(1_mpiint, 'if you want to compute wedge coeffs online, you need to supply wedge coords')
      call setup_default_wedge_geometry( &
        real(wedge_coords(1:2), ireals), &
        real(wedge_coords(3:4), ireals), &
        real(wedge_coords(5:6), ireals), &
        real(aspect_zx, ireals), vertices)
      call get_coeff_bmc(OPP, vertices, real(tauz, ireals), real(w0, ireals), real(g, ireals), ldir, C, in_angles)
      return
    endif

    if(ldebug_optprop) then
      if(.not.present(wedge_coords)) call CHKERR(1_mpiint, 'If you use an wedge OPP object, I highly recommend that you provide the wedge coordinates')
    endif

    if(ldebug_optprop) then
      if(.not.all(approx(wedge_coords([1,2,4]), 0._irealLUT)) &
        .or. .not.approx(wedge_coords(3), 1._irealLUT)) then
        print *,'wedge_coords:', wedge_coords
        call CHKERR(1_mpiint, 'provided wedge coords have to in local bmc coordinate system!')
      endif
      call check_inp(OPP, tauz, w0, g, aspect_zx, ldir, C, in_angles)
    endif

    if(ldebug_optprop) then
      if(.not.approx(g,0._irealLUT)) call CHKERR(1_mpiint, 'wedge LUT does not have values for other than g==0')
    endif

    if(handle_aspect_zx_1D_case()) then
      ierr = OPP_1D_RETCODE
      return
    endif

    call do_wedge_lookup(tauz, w0, aspect_zx, ldir, in_angles)

    contains
      subroutine do_wedge_lookup(tauz, w0, aspect_zx, ldir, in_angles)
        real(irealLUT), intent(in) :: tauz, w0, aspect_zx
        logical,intent(in)       :: ldir
        real(irealLUT),intent(in),optional :: in_angles(:)
        real(irealLUT) :: save_theta

        associate( C_pnt => wedge_coords(5:6) )

          select case (coeff_mode)
          case(i0) ! LookUpTable Mode
            if(present(in_angles)) then ! obviously we want the direct coefficients
              if(in_angles(2).gt.90._irealLUT) then
                save_theta = 180._irealLUT - in_angles(2)
              else
                save_theta = in_angles(2)
              endif
              if(ldir) then ! dir2dir
                call OPP%OPP_LUT%LUT_get_dir2dir([tauz, w0, aspect_zx, C_pnt(1), C_pnt(2), in_angles(1), save_theta], C)
              else ! dir2diff
                call OPP%OPP_LUT%LUT_get_dir2diff([tauz, w0, aspect_zx, C_pnt(1), C_pnt(2), in_angles(1), save_theta], C)
              endif
              call handle_sza_gt_90_case()
            else
              ! diff2diff
              call OPP%OPP_LUT%LUT_get_diff2diff([tauz, w0, aspect_zx, C_pnt(1), C_pnt(2)], C)
            endif

          case default
            call CHKERR(1_mpiint, 'particular value of coeff mode in optprop_parameters is not defined: '//itoa(coeff_mode))
          end select
        end associate
      end subroutine

      logical function handle_aspect_zx_1D_case()
        real(ireals) :: c11,c12,c13,c23,c33,g1,g2
        real(irealLUT) :: restricted_aspect_zx
        real(ireals) :: save_theta

        handle_aspect_zx_1D_case = .False.

        !TODO: here we may have incoming radiation at the sides and we just drop that
        ! this has to be fixed for anisotropic grids

        if(present(in_angles)) then
          if(in_angles(2).gt.90._irealLUT) then
            save_theta = 180._irealLUT - in_angles(2)
          else
            save_theta = in_angles(2)
          endif
          !if(aspect_zx.gt.OPP%OPP_LUT%dirconfig%dims(3)%vrange(2)) then
          if(aspect_zx.ge.twostr_ratio) then
            C = zero

            call eddington_coeff_zdun(&
              real(tauz, ireals), &
              real(w0, ireals), &
              real(g, ireals), &
              cos(deg2rad(save_theta)), &
              c11,c12,c13,c23,c33,g1,g2)

            if(ldir) then
              ! set the transport coeffs for src top to zero, leave the rest.
              C(21) = real(c33, irealLUT) ! from top to bot
              C(22:24) = 1 ! from sides to bot
            else
              C(1) = real(c13, irealLUT)
              C(7*5+1) = real(c23, irealLUT)
            endif

            handle_aspect_zx_1D_case = .True.

          elseif(aspect_zx.lt.OPP%OPP_LUT%dirconfig%dims(3)%vrange(1)) then
            restricted_aspect_zx = min(max(aspect_zx, OPP%OPP_LUT%dirconfig%dims(3)%vrange(1)), &
              OPP%OPP_LUT%dirconfig%dims(3)%vrange(2))
            call do_wedge_lookup(tauz, w0, restricted_aspect_zx, ldir, in_angles)
            handle_aspect_zx_1D_case = .True.
          endif

        else ! diffuse

          !if(aspect_zx.gt.OPP%OPP_LUT%diffconfig%dims(3)%vrange(2)) then
          if(aspect_zx.ge.twostr_ratio) then
            C = zero

            call eddington_coeff_zdun(&
              real(tauz, ireals), &
              real(w0, ireals), &
              real(g, ireals), &
              one, &
              c11,c12,c13,c23,c33,g1,g2)

            ! transmission & reflection towards top plate
            C(1)     = real(c12, irealLUT)
            C(8)     = real(c11, irealLUT)
            ! and bot plate
            C(7*8+1) = real(c11, irealLUT)
            C(8*8)   = real(c12, irealLUT)

            handle_aspect_zx_1D_case = .True.

          elseif(aspect_zx.lt.OPP%OPP_LUT%diffconfig%dims(3)%vrange(1)) then
            restricted_aspect_zx = min(max(aspect_zx, OPP%OPP_LUT%diffconfig%dims(3)%vrange(1)), &
              OPP%OPP_LUT%diffconfig%dims(3)%vrange(2))
            call do_wedge_lookup(tauz, w0, restricted_aspect_zx, ldir, in_angles)
            handle_aspect_zx_1D_case = .True.
          endif

        endif
      end function

      subroutine handle_sza_gt_90_case()
        if(in_angles(2).gt.90._irealLUT) then
          if(ldir) then
            call swap(C( 1: 5),C(21:25))
            call swap(C( 6), C(10))
            call swap(C(11), C(15))
            call swap(C(16), C(20))
          else
            call swap(C( 1: 5), C(36:40))

            call swap(C( 6:10), C(11:15))
            call swap(C( 6), C(10))
            call swap(C(11), C(15))

            call swap(C(16:20), C(21:25))
            call swap(C(16), C(20))
            call swap(C(21), C(25))

            call swap(C(26:30), C(31:35))
            call swap(C(26), C(30))
            call swap(C(31), C(35))
          endif
        endif
      end subroutine
  end subroutine

  subroutine boxmc_lut_call(OPP, tauz, w0, g, aspect_zx, dir, C, angles, lswitch_east, lswitch_north)
    class(t_optprop)                  :: OPP
    logical,intent(in)                :: dir
    real(irealLUT),intent(in)           :: tauz, w0, g, aspect_zx
    real(irealLUT),intent(in),optional  :: angles(:)
    logical,intent(in),optional       :: lswitch_east, lswitch_north
    real(irealLUT),intent(out)          :: C(:)

    logical,parameter :: compute_coeff_online=.False.
    real(ireals), allocatable :: vertices(:)

    if(compute_coeff_online) then
      call setup_default_unit_cube_geometry(one, one, real(aspect_zx, ireals), vertices)
      call get_coeff_bmc(OPP, vertices, real(tauz, ireals), real(w0, ireals), real(g, ireals), dir, C, angles)
      return
    endif

    if(ldebug_optprop) call check_inp(OPP, tauz, w0, g, aspect_zx, dir, C, angles)

    select case (coeff_mode)

    case(i0) ! LookUpTable Mode

      if(present(angles)) then ! obviously we want the direct coefficients
        if(dir) then ! dir2dir
          call OPP%OPP_LUT%LUT_get_dir2dir([tauz, w0, aspect_zx, g, angles(1), angles(2)], C)
          call OPP%dir2dir_coeff_symmetry(C, lswitch_east, lswitch_north)
        else         ! dir2diff
          call OPP%OPP_LUT%LUT_get_dir2diff([tauz, w0, aspect_zx, g, angles(1), angles(2)], C)
          call OPP%dir2diff_coeff_symmetry(C, lswitch_east, lswitch_north)
        endif
      else
        ! diff2diff
        call OPP%OPP_LUT%LUT_get_diff2diff([tauz, w0, aspect_zx, g], C)
      endif


    case(i1) ! ANN

      if(present(angles)) then ! obviously we want the direct coefficients
        if(dir) then ! specifically the dir2dir
          call ANN_get_dir2dir(tauz, w0, g, aspect_zx, angles(1), angles(2), C)
        else ! dir2diff
          call ANN_get_dir2diff(tauz, w0, g, aspect_zx, angles(1), angles(2), C)
        endif
      else
        ! diff2diff
        call ANN_get_diff2diff(tauz, w0, g, aspect_zx, C)
      endif

    case default
      call CHKERR(1_mpiint, 'particular value of coeff mode in optprop_parameters is not defined: '//itoa(coeff_mode))
    end select

  end subroutine

  subroutine get_coeff_bmc(OPP, vertices, tauz, w0, g, dir, C, angles)
      class(t_optprop) :: OPP
      real(ireals),intent(in) :: tauz, w0, g, vertices(:)
      logical,intent(in) :: dir
      real(irealLUT),intent(out):: C(:)
      real(irealLUT),intent(in),optional :: angles(2)

      real(irealLUT) :: S_diff(OPP%OPP_LUT%diff_streams),T_dir(OPP%OPP_LUT%dir_streams)
      real(irealLUT) :: S_tol (OPP%OPP_LUT%diff_streams),T_tol(OPP%OPP_LUT%dir_streams)
      integer(iintegers) :: isrc

      real(ireals), parameter :: atol=2e-4_ireals, rtol=1e-2_ireals

      if(present(angles)) then
          do isrc=1,OPP%OPP_LUT%dir_streams
            call OPP%OPP_LUT%bmc_wrapper(isrc, &
              real(vertices, ireals), &
              real(tauz, ireals), &
              real(w0, ireals), &
              real(g, ireals), &
              .True.,   &
              real(angles(1), ireals), &
              real(angles(2), ireals), &
              mpi_comm_self, &
              S_diff, T_dir, S_tol, T_tol, &
              inp_atol=atol, inp_rtol=rtol)
            if(dir) then !dir2dir
              C(isrc:OPP%OPP_LUT%dir_streams**2:OPP%OPP_LUT%dir_streams) = T_dir
            else ! dir2diff
              C(isrc:OPP%OPP_LUT%dir_streams*OPP%OPP_LUT%diff_streams:OPP%OPP_LUT%dir_streams) = S_diff
            endif
          enddo
      else
        ! diff2diff
        do isrc=1,OPP%OPP_LUT%diff_streams
            call OPP%OPP_LUT%bmc_wrapper(isrc, &
              real(vertices, ireals), &
              real(tauz, ireals), &
              real(w0, ireals), &
              real(g, ireals), &
              .False.,   &
              zero, zero, &
              mpi_comm_self, &
              S_diff, T_dir, S_tol, T_tol, &
              inp_atol=atol, inp_rtol=rtol)
          C(isrc:OPP%OPP_LUT%diff_streams**2:OPP%OPP_LUT%diff_streams) = S_diff
        enddo
      endif ! angles_present

  end subroutine

  subroutine check_inp(OPP, tauz, w0, g, aspect_zx, dir, C, angles)
    class(t_optprop) :: OPP
    real(irealLUT),intent(in) :: tauz, w0, g, aspect_zx
    logical,intent(in) :: dir
    real(irealLUT),intent(in):: C(:)
    real(irealLUT),intent(in),optional  :: angles(:)
    if( (any([aspect_zx, tauz, w0, g].lt.zero)) .or. (any(isnan([aspect_zx, tauz, w0, g]))) ) then
      print *,'optprop_lookup_coeff :: corrupt optical properties: bg:: ',[aspect_zx, tauz, w0, g]
      call exit
    endif
    !if(.not.approx(g,zero)) then
    !  call CHKERR(1_mpiint, 'currently the LUT calls do not have a dimensions for assym param g. has to be zero')
    !endif
    if(present(angles)) then
      if(dir .and. size(C).ne. OPP%OPP_LUT%dir_streams**2) then
        print *,'direct called get_coeff with wrong shaped output array:',size(C),'should be ',OPP%OPP_LUT%dir_streams**2
      endif
      if(.not.dir .and. size(C).ne. OPP%OPP_LUT%diff_streams*OPP%OPP_LUT%dir_streams) then
        print *,'dir2diffuse called get_coeff with wrong shaped output array:',size(C),'should be',OPP%OPP_LUT%diff_streams*OPP%OPP_LUT%dir_streams
      endif
    else
      if(dir .and. size(C).ne. OPP%OPP_LUT%diff_streams) then
        print *,'diff2diff called get_coeff with wrong shaped output array:',size(C),'should be ',OPP%OPP_LUT%diff_streams
      endif
      if(.not.dir .and. size(C).ne. OPP%OPP_LUT%diff_streams**2) then
        print *,'diff2diff called get_coeff with wrong shaped output array:',size(C),'should be ',OPP%OPP_LUT%diff_streams**2
      endif
    endif
  end subroutine

  subroutine dir2diff_coeff_symmetry(OPP, coeff, lswitch_east, lswitch_north)

    class(t_optprop) :: OPP
    logical, intent(in),optional :: lswitch_east, lswitch_north
    real(irealLUT),intent(inout) :: coeff(:)

    integer(iintegers)              :: dof
    real(irealLUT)                    :: newcoeff(size(coeff))

    select type(OPP)
      class is (t_optprop_1_2)
        continue

      class is (t_optprop_3_6)
        !for solver_3_6 only the offset is changing in those sides which should be switched
        dof = 3
        if(present(lswitch_east)) then
          if(lswitch_east) then
            newcoeff = coeff
            coeff(7:9)   = newcoeff([1, 2, 3] + dof*3)
            coeff(10:12) = newcoeff([1, 2, 3] + dof*2)
          endif
        endif
        if(present(lswitch_north)) then
          if(lswitch_north) then
            newcoeff = coeff
            coeff(13:15) = newcoeff([1, 2, 3] + dof*5)
            coeff(16:18) = newcoeff([1, 2, 3] + dof*4)
          endif
        endif

      class is (t_optprop_3_10)
        !for solver_3_10 the offset is chaning and the destination order
        dof = 3
        if(present(lswitch_east)) then
          if(lswitch_east) then
            newcoeff = coeff
            coeff( 1: 3) = newcoeff([1, 2, 3]        )
            coeff( 4: 6) = newcoeff([1, 2, 3] + dof*1)
            coeff( 7: 9) = newcoeff([1, 2, 3] + dof*3)
            coeff(10:12) = newcoeff([1, 2, 3] + dof*2)
            coeff(13:15) = newcoeff([1, 2, 3] + dof*5)
            coeff(16:18) = newcoeff([1, 2, 3] + dof*4)
            coeff(19:21) = newcoeff([1, 2, 3] + dof*6)
            coeff(22:24) = newcoeff([1, 2, 3] + dof*7)
            coeff(25:27) = newcoeff([1, 2, 3] + dof*8)
            coeff(28:30) = newcoeff([1, 2, 3] + dof*9)
          endif
        endif
        if(present(lswitch_north)) then
          if(lswitch_north) then
            newcoeff = coeff
            coeff( 1: 3) = newcoeff([1, 2, 3]        )
            coeff( 4: 6) = newcoeff([1, 2, 3] + dof*1)
            coeff( 7: 9) = newcoeff([1, 2, 3] + dof*3)
            coeff(10:12) = newcoeff([1, 2, 3] + dof*2)
            coeff(13:15) = newcoeff([1, 2, 3] + dof*5)
            coeff(16:18) = newcoeff([1, 2, 3] + dof*4)
            coeff(19:21) = newcoeff([1, 2, 3] + dof*6)
            coeff(22:24) = newcoeff([1, 2, 3] + dof*7)
            coeff(25:27) = newcoeff([1, 2, 3] + dof*8)
            coeff(28:30) = newcoeff([1, 2, 3] + dof*9)
          endif
        endif


      class is (t_optprop_3_16)
        if(present(lswitch_east)) then
          if(lswitch_east) then
            call CHKERR(1_mpiint, 'not yet implemented')
          endif
        endif
        if(present(lswitch_north)) then
          if (lswitch_north) then
            call CHKERR(1_mpiint, 'not yet implemented')
          endif
        endif


      class is (t_optprop_8_10)
        !for solver_8_10 the offset is chaning and the destination order
        dof = 8
        if(present(lswitch_east)) then
          if(lswitch_east) then
            newcoeff = coeff
            coeff(1:8)   = newcoeff([2, 1, 4, 3, 5, 6, 7, 8]        )
            coeff(9:16)  = newcoeff([2, 1, 4, 3, 5, 6, 7, 8] +dof*1 )
            coeff(17:24) = newcoeff([2, 1, 4, 3, 5, 6, 7, 8] +dof*3 )
            coeff(25:32) = newcoeff([2, 1, 4, 3, 5, 6, 7, 8] +dof*2 )
            coeff(33:40) = newcoeff([2, 1, 4, 3, 5, 6, 7, 8] +dof*5 )
            coeff(41:48) = newcoeff([2, 1, 4, 3, 5, 6, 7, 8] +dof*4 )
            coeff(49:56) = newcoeff([2, 1, 4, 3, 5, 6, 7, 8] +dof*6 )
            coeff(57:64) = newcoeff([2, 1, 4, 3, 5, 6, 7, 8] +dof*7 )
            coeff(65:72) = newcoeff([2, 1, 4, 3, 5, 6, 7, 8] +dof*8 )
            coeff(73:80) = newcoeff([2, 1, 4, 3, 5, 6, 7, 8] +dof*9 )
          endif
        endif
        if(present(lswitch_north)) then
          if (lswitch_north) then
            newcoeff =coeff
            coeff(1:8)   = newcoeff([3, 4, 1, 2, 5, 6, 7, 8]        )
            coeff(9:16)  = newcoeff([3, 4, 1, 2, 5, 6, 7, 8] +dof*1 )
            coeff(17:24) = newcoeff([3, 4, 1, 2, 5, 6, 7, 8] +dof*3 )
            coeff(25:32) = newcoeff([3, 4, 1, 2, 5, 6, 7, 8] +dof*2 )
            coeff(33:40) = newcoeff([3, 4, 1, 2, 5, 6, 7, 8] +dof*5 )
            coeff(41:48) = newcoeff([3, 4, 1, 2, 5, 6, 7, 8] +dof*4 )
            coeff(49:56) = newcoeff([3, 4, 1, 2, 5, 6, 7, 8] +dof*6 )
            coeff(57:64) = newcoeff([3, 4, 1, 2, 5, 6, 7, 8] +dof*7 )
            coeff(65:72) = newcoeff([3, 4, 1, 2, 5, 6, 7, 8] +dof*8 )
            coeff(73:80) = newcoeff([3, 4, 1, 2, 5, 6, 7, 8] +dof*9 )
          endif
        endif

      class is (t_optprop_8_16)
        if(present(lswitch_east)) then
          if(lswitch_east) then
            call CHKERR(1_mpiint, 'not yet implemented')
          endif
        endif
        if(present(lswitch_north)) then
          if (lswitch_north) then
            call CHKERR(1_mpiint, 'not yet implemented')
          endif
        endif

      class is (t_optprop_8_18)
        if(present(lswitch_east)) then
          if(lswitch_east) then
            call CHKERR(1_mpiint, 'not yet implemented')
          endif
        endif
        if(present(lswitch_north)) then
          if (lswitch_north) then
            call CHKERR(1_mpiint, 'not yet implemented')
          endif
        endif

    end select

  end subroutine

  subroutine dir2dir_coeff_symmetry(OPP, coeff, lswitch_east, lswitch_north)
    class(t_optprop)            :: OPP
    logical, intent(in),optional:: lswitch_east, lswitch_north
    real(irealLUT),intent(inout)  :: coeff(:)

    integer(iintegers) :: dof
    real(irealLUT)       :: newcoeff(size(coeff))

    select type(OPP)
      class is (t_optprop_1_2)
        continue

      class is (t_optprop_3_6)
        !nothing to do because of symmetrie
        continue

      class is (t_optprop_3_10)
        !nothing to do because of symmetrie
        continue

      class is (t_optprop_3_16)
        continue

      class is (t_optprop_8_10)
        call symmetry_8()

      class is (t_optprop_8_16)
        call symmetry_8()

      class is (t_optprop_8_18)
        call symmetry_8()
    end select

  contains
    subroutine symmetry_8()
      dof = 8
      if(present(lswitch_east)) then
        if(lswitch_east) then
          newcoeff = coeff
          coeff(1:8)   = newcoeff([2, 1, 4, 3, 5, 6, 7, 8]+dof  )
          coeff(9:16)  = newcoeff([2, 1, 4, 3, 5, 6, 7, 8]      )
          coeff(17:24) = newcoeff([2, 1, 4, 3, 5, 6, 7, 8]+dof*3)
          coeff(25:32) = newcoeff([2, 1, 4, 3, 5, 6, 7, 8]+dof*2)
          coeff(33:40) = newcoeff([2, 1, 4, 3, 5, 6, 7, 8]+dof*4)
          coeff(41:48) = newcoeff([2, 1, 4, 3, 5, 6, 7, 8]+dof*5)
          coeff(49:56) = newcoeff([2, 1, 4, 3, 5, 6, 7, 8]+dof*6)
          coeff(57:64) = newcoeff([2, 1, 4, 3, 5, 6, 7, 8]+dof*7)
        endif
      endif
      if(present(lswitch_north)) then
        if (lswitch_north) then
          newcoeff = coeff
          coeff(1:8)   = newcoeff([3, 4, 1, 2, 5, 6, 7, 8]+dof*2)
          coeff(9:16)  = newcoeff([3, 4, 1, 2, 5, 6, 7, 8]+dof*3)
          coeff(17:24) = newcoeff([3, 4, 1, 2, 5, 6, 7, 8]      )
          coeff(25:32) = newcoeff([3, 4, 1, 2, 5, 6, 7, 8]+dof  )
          coeff(33:40) = newcoeff([3, 4, 1, 2, 5, 6, 7, 8]+dof*4)
          coeff(41:48) = newcoeff([3, 4, 1, 2, 5, 6, 7, 8]+dof*5)
          coeff(49:56) = newcoeff([3, 4, 1, 2, 5, 6, 7, 8]+dof*6)
          coeff(57:64) = newcoeff([3, 4, 1, 2, 5, 6, 7, 8]+dof*7)
        endif
      endif
    end subroutine

  end subroutine
end module
