module test_boxmc_3_6_tau_scaling
  use m_boxmc, only : t_boxmc, t_boxmc_3_6
  use m_data_parameters, only :     &
    mpiint, ireals, iintegers,      &
    one, zero, i1, default_str_len, &
    init_mpi_data_parameters
  use m_optprop_parameters, only : stddev_atol
  use m_boxmc_geometry, only : setup_default_unit_cube_geometry
  use m_helper_functions, only: itoa

  use pfunit_mod
  implicit none

  real(ireals) :: bg(3), phi,theta,dx,dy,dz
  real(ireals) :: S(6),T(3), S_target(6), T_target(3)
  real(ireals) :: S_tol(6),T_tol(3)
  real(ireals), allocatable :: vertices(:)

  type(t_boxmc_3_6) :: bmc_3_6

  integer(mpiint) :: myid,mpierr,numnodes,comm
  character(len=120) :: msg

  real(ireals),parameter :: sigma = 3 ! normal test range for coefficients

  real(ireals),parameter :: atol=1e-3, rtol=1e-2
  !real(ireals),parameter :: atol=1e-5, rtol=1e-3
contains

  @before
  subroutine setup(this)
    class (MpiTestMethod), intent(inout) :: this
    comm     = this%getMpiCommunicator()
    numnodes = this%getNumProcesses()
    myid     = this%getProcessRank()

    call init_mpi_data_parameters(comm)

    call bmc_3_6%init(comm)

    if(myid.eq.0) print *,'Testing Box-MonteCarlo model with tolerances atol/rtol :: ',atol,rtol

    phi   =  0
    theta =  0

    dx = 100
    dy = dx
    dz = 50
    call setup_default_unit_cube_geometry(dx, dy, dz, vertices)

    S_target = zero
    T_target = zero
  end subroutine setup

  @after
  subroutine teardown(this)
    class (MpiTestMethod), intent(inout) :: this
    if(myid.eq.0) print *,'Finishing boxmc tests module'
  end subroutine teardown

  @test(npes =[1])
  subroutine test_boxmc_tau_scaling1(this)
    class (MpiTestMethod), intent(inout) :: this
    integer(iintegers) :: src, itau_scaling
    real(ireals) :: tau, tau_scaling

    ! from top to bot face
    phi = 0; theta = 0

    ! direct to diffuse tests
    bg  = [1e-9_ireals, 1e-3_ireals, zero ]

    tau = (bg(1)+bg(2)) * dz

    S_target(1:2) = (1.21608E-02 + 1.21106E-02)/2
    S_target(3:6) = (6.10860E-03 + 6.07660E-03 + 6.12260E-03 + 6.14420E-03)/4

    T_target = zero
    T_target(1) = exp(-tau)

    src = 1
    do itau_scaling=0,2
      tau_scaling = 10.**itau_scaling
      print *,'Tau Roulette', tau_scaling
      call bmc_3_6%get_coeff(comm,bg,src,.True.,phi,theta,vertices,S,T,S_tol,T_tol, &
        inp_atol=atol, inp_rtol=rtol, inp_tau_scaling=tau_scaling)
      call check(S_target,T_target, S,T, msg=' test_boxmc_tau_scaling_1_'//itoa(itau_scaling))
    enddo

  end subroutine

  @test(npes =[1])
  subroutine test_boxmc_tau_scaling2(this)
    class (MpiTestMethod), intent(inout) :: this
    integer(iintegers) :: src, itau_scaling
    real(ireals) :: tau, tau_scaling

    ! from top to bot face
    phi = 0; theta = 0

    ! direct to diffuse tests
    bg  = [1e-30_ireals, 1e-5_ireals/dz, zero ]

    tau = (bg(1)+bg(2)) * dz

    S_target(1:2) = (2.56000E-06 + 2.39000E-06 + 2.47300E-06 + 2.50900E-06 )/4
    S_target(3:6) = (1.26000E-06 + 1.25000E-06 + 1.38000E-06 + 1.32000E-06 &
      + 1.24400E-06 + 1.23000E-06 + 1.28000E-06 + 1.26000E-06)/8

    T_target = zero
    T_target(1) = exp(-tau)

    src = 1
    do itau_scaling=0,9
      tau_scaling = 10.**itau_scaling
      print *,'Tau Roulette', tau_scaling
      call bmc_3_6%get_coeff(comm,bg,src,.True.,phi,theta,vertices,S,T,S_tol,T_tol, &
        inp_atol=atol, inp_rtol=rtol, inp_tau_scaling=tau_scaling)
      call check(S_target,T_target, S,T, msg=' test_boxmc_tau_scaling_2_'//itoa(itau_scaling))
    enddo
  end subroutine
  !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

  subroutine check(S_target,T_target, S,T, msg)
    real(ireals),intent(in),dimension(:) :: S_target,T_target, S,T

    character(len=*),optional :: msg
    character(default_str_len) :: local_msgS, local_msgT

    if(myid.eq.0) then
      print*,''

      if( present(msg) ) then
        write(local_msgS,*) trim(msg),':: Diffuse boxmc coefficient not as '
        write(local_msgT,*) trim(msg),':: Direct  boxmc coefficient not as '
        print *,msg
      else
        write(local_msgS,*) 'Diffuse boxmc coefficient not as '
        write(local_msgT,*) 'Direct  boxmc coefficient not as '
      endif

      print*,'---------------------'
      write(*, FMT='( " diffuse ::  :: ",6(es12.5) )' ) S
      write(*, FMT='( " target  ::  :: ",6(es12.5) )' ) S_target
      write(*, FMT='( " diff    ::  :: ",6(es12.5) )' ) S_target-S
      print*,''
      write(*, FMT='( " direct  ::  :: ", 8(es12.5) )' ) T
      write(*, FMT='( " target  ::  :: ", 8(es12.5) )' ) T_target
      write(*, FMT='( " diff    ::  :: ", 8(es12.5) )' ) T_target-T
      print*,'---------------------'
      print*,''

      @assertEqual(S_target, S, atol*sigma, local_msgS )
      @assertLessThanOrEqual   (zero, S)
      @assertGreaterThanOrEqual(one , S)

      @assertEqual(T_target, T, atol*sigma, local_msgT )
      @assertLessThanOrEqual   (zero, T)
      @assertGreaterThanOrEqual(one , T)
    endif
  end subroutine

end module
