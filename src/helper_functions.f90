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

module m_helper_functions
  use iso_fortran_env, only: INT32, INT64, REAL32, REAL64
  use m_data_parameters,only : iintegers, mpiint, ireals, irealLUT, ireal_dp, &
    i1, pi, pi32, pi64, zero, one, imp_ireals, imp_REAL32, imp_REAL64, imp_logical, default_str_len, &
    imp_int4, imp_int8, imp_iinteger

  use mpi

  implicit none

  private
  public imp_bcast,cross_2d, cross_3d,rad2deg,deg2rad,rmse,meanval,approx,rel_approx,                           &
    delta_scale_optprop,delta_scale,cumsum, cumprod,                                                                 &
    inc, mpi_logical_and,mpi_logical_or,imp_allreduce_min,imp_allreduce_max,imp_reduce_sum,                          &
    gradient, read_ascii_file_2d, meanvec, swap, imp_allgather_int_inplace, reorder_mpi_comm,                        &
    CHKERR, CHKWARN, assertEqual,                                                                                    &
    compute_normal_3d, determine_normal_direction, spherical_2_cartesian, angle_between_two_vec, hit_plane,          &
    pnt_in_triangle, distance_to_edge, rotation_matrix_world_to_local_basis, rotation_matrix_local_basis_to_world,   &
    vec_proj_on_plane, get_arg, unique, itoa, ftoa, char_arr_to_str, cstr, strF2C,                                   &
    distance, triangle_area_by_edgelengths, triangle_area_by_vertices,                                               &
    ind_1d_to_nd, ind_nd_to_1d, ndarray_offsets, get_mem_footprint, imp_allreduce_sum, imp_allreduce_mean,           &
    resize_arr, reverse, rotate_angle_x, rotate_angle_y, rotate_angle_z, rotation_matrix_around_axis_vec,            &
    solve_quadratic, linspace, assert_arr_is_monotonous

  interface rotate_angle_x
    module procedure rotate_angle_x_r32, rotate_angle_x_r64
  end interface
  interface rotate_angle_y
    module procedure rotate_angle_y_r32, rotate_angle_y_r64
  end interface
  interface rotate_angle_z
    module procedure rotate_angle_z_r32, rotate_angle_z_r64
  end interface
  interface rmse
    module procedure rmse_r32, rmse_r64
  end interface
  interface spherical_2_cartesian
    module procedure spherical_2_cartesian_r32, spherical_2_cartesian_r64
  end interface
  interface rad2deg
    module procedure rad2deg_r32, rad2deg_r64
  end interface
  interface deg2rad
    module procedure deg2rad_r32, deg2rad_r64
  end interface
  interface approx
    module procedure approx_r32, approx_r64
  end interface
  interface distance
    module procedure distance_r32, distance_r64
  end interface
  interface itoa
    module procedure itoa_i4, itoa_i8, itoa_1d_i4, itoa_1d_i8
  end interface
  interface ftoa
    module procedure ftoa_r32, ftoa_r64, ftoa_1d_r32, ftoa_1d_r64
  end interface
  interface meanval
    module procedure meanval_1d_r4, meanval_2d_r4, meanval_3d_r4, &
        meanval_1d_r8, meanval_2d_r8, meanval_3d_r8
  end interface
  interface imp_allreduce_mean
    module procedure imp_allreduce_mean_2d, imp_allreduce_mean_3d
  end interface
  interface imp_allreduce_sum
    module procedure imp_allreduce_sum_ireals, imp_allreduce_sum_i32, imp_allreduce_sum_i64
  end interface
  interface imp_allreduce_min
    module procedure imp_allreduce_min_ireals, imp_allreduce_min_iintegers
  end interface
  interface imp_allreduce_max
    module procedure imp_allreduce_max_ireals, imp_allreduce_max_iintegers
  end interface
  interface imp_bcast
    module procedure imp_bcast_real_1d, imp_bcast_real_3d, imp_bcast_real_5d, &
        imp_bcast_real32_2d, imp_bcast_real64_2d, imp_bcast_real32_2d_ptr, imp_bcast_real64_2d_ptr, &
        imp_bcast_int_1d, imp_bcast_int_2d, imp_bcast_int4, imp_bcast_int8, imp_bcast_real, imp_bcast_logical
  end interface
  interface imp_reduce_sum
    module procedure imp_reduce_sum_r32, imp_reduce_sum_r64
  end interface
  interface get_arg
    module procedure get_arg_logical, get_arg_i32, get_arg_i64, get_arg_real32, get_arg_real64, get_arg_char
  end interface
  interface swap
    module procedure swap_iintegers, swap_r32, swap_r64
  end interface
  interface cumsum
    module procedure cumsum_iintegers, cumsum_ireals
  end interface
  interface cumprod
    module procedure cumprod_iintegers, cumprod_ireals
  end interface
  interface resize_arr
    module procedure resize_arr_int32, resize_arr_int64
  end interface
  interface reverse
    module procedure reverse_1d_real32, reverse_2d_real32, reverse_1d_real64, reverse_2d_real64, &
        reverse_3d_real32, reverse_3d_real64, reverse_4d_real32, reverse_4d_real64
  end interface
  interface assertEqual
    module procedure assertEqual_i32, assertEqual_i64
  end interface

  interface pnt_in_triangle
    module procedure pnt_in_triangle_r32, pnt_in_triangle_r64
  end interface
  interface pnt_in_rectangle
    module procedure pnt_in_rectangle_r32, pnt_in_rectangle_r64
  end interface
  interface pnt_in_triangle_convex_hull
    module procedure pnt_in_triangle_convex_hull_r32, pnt_in_triangle_convex_hull_r64
  end interface
  interface cross_2d
    module procedure cross_2d_r32, cross_2d_r64
  end interface
  interface cross_3d
    module procedure cross_3d_r32, cross_3d_r64
  end interface
  interface angle_between_two_vec
    module procedure angle_between_two_vec_r32, angle_between_two_vec_r64
  end interface
  interface compute_normal_3d
    module procedure compute_normal_3d_r32, compute_normal_3d_r64
  end interface
  interface rotation_matrix_local_basis_to_world
    module procedure rotation_matrix_local_basis_to_world_r32, rotation_matrix_local_basis_to_world_r64
  end interface

  interface distances_to_triangle_edges
    module procedure distances_to_triangle_edges_r32, distances_to_triangle_edges_r64
  end interface
  interface distance_to_edge
    module procedure distance_to_edge_r32, distance_to_edge_r64
  end interface
  interface triangle_area_by_vertices
    module procedure triangle_area_by_vertices_r32, triangle_area_by_vertices_r64
  end interface
  interface triangle_area_by_edgelengths
    module procedure triangle_area_by_edgelengths_r32, triangle_area_by_edgelengths_r64
  end interface

  interface delta_scale
    module procedure delta_scale_r32, delta_scale_r64
  end interface
  interface delta_scale_optprop
    module procedure delta_scale_optprop_r32, delta_scale_optprop_r64
  end interface

  interface solve_quadratic
    module procedure solve_quadratic_r32, solve_quadratic_r64
  end interface

  interface linspace
    module procedure linspace_r32, linspace_r64
  end interface

  interface assert_arr_is_monotonous
    module procedure assert_arr_is_monotonous_r32, assert_arr_is_monotonous_r64
  end interface

  integer(iintegers), parameter :: npar_cumprod=8
  contains

    function strF2C(str)
      use iso_c_binding, only: C_NULL_CHAR
      character(len=*), intent(in) :: str
      character(len=len_trim(str)+1) :: strF2C
      strF2C = trim(str)//C_NULL_CHAR
    end function

    pure elemental subroutine swap_r32(x,y)
      real(REAL32),intent(inout) :: x,y
      real(REAL32) :: tmp
      tmp = x; x = y; y = tmp
    end subroutine
    pure elemental subroutine swap_r64(x,y)
      real(REAL64),intent(inout) :: x,y
      real(REAL64) :: tmp
      tmp = x; x = y; y = tmp
    end subroutine
    pure elemental subroutine swap_iintegers(x,y)
      integer(iintegers),intent(inout) :: x,y
      integer(iintegers) :: tmp
      tmp = x
      x = y
      y = tmp
    end subroutine
    pure elemental subroutine inc(x,i)
      real(ireals),intent(inout) :: x
      real(ireals),intent(in) :: i
      x=x+i
    end subroutine

    subroutine CHKERR(ierr, descr)
      integer(mpiint),intent(in) :: ierr
      character(len=*), intent(in), optional :: descr
      integer(mpiint) :: mpierr

#ifdef __RELEASE_BUILD__
      return
#endif

      if(ierr.ne.0) then
        call CHKWARN(ierr, descr)
        call mpi_abort(mpi_comm_world, ierr, mpierr)
      endif
    end subroutine

    subroutine CHKWARN(ierr, descr)
      integer(mpiint),intent(in) :: ierr
      character(len=*), intent(in), optional :: descr
      integer(mpiint) :: myid, mpierr

#ifdef __RELEASE_BUILD__
      return
#endif

      if(ierr.ne.0) then
        call mpi_comm_rank(MPI_COMM_WORLD, myid, mpierr)
        if(present(descr)) then
          print *,myid, 'Warning:', ierr, ':', trim(descr)
        else
          print *,myid, 'Warning:', ierr
        endif
#ifdef _GNU
        call BACKTRACE
#endif
      endif
    end subroutine

    subroutine assertEqual_i32(t, i, msg)
      integer(INT32),intent(in) :: t, i
      character(len=*), intent(in), optional :: msg
      if(t.ne.i) then
        if(present(msg)) then
          call CHKERR(int(t-i, mpiint), itoa(i)//'.ne.'//itoa(t)//' :: '//msg)
        else
          call CHKERR(int(t-i, mpiint), itoa(i)//'.ne.'//itoa(t))
        endif
      endif
    end subroutine
    subroutine assertEqual_i64(t, i, msg)
      integer(INT64),intent(in) :: t, i
      character(len=*), intent(in), optional :: msg
      if(t.ne.i) then
        if(present(msg)) then
          call CHKERR(int(t-i, mpiint), itoa(i)//'.ne.'//itoa(t)//' :: '//msg)
        else
          call CHKERR(int(t-i, mpiint), itoa(i)//'.ne.'//itoa(t))
        endif
      endif
    end subroutine

    pure function itoa_i4(i) result(res)
      character(:),allocatable :: res
      integer(kind=INT32),intent(in) :: i
      character(len=range(i)+2) :: tmp
      write(tmp,'(i0)') i
      res = trim(tmp)
    end function
    pure function itoa_i8(i) result(res)
      character(:),allocatable :: res
      integer(kind=INT64),intent(in) :: i
      character(range(i)+2) :: tmp
      write(tmp,'(i0)') i
      res = trim(tmp)
    end function
    pure function itoa_1d_i4(i) result(res)
      character(:),allocatable :: res
      integer(kind=INT32),intent(in) :: i(:)
      character(range(i)+2) :: tmp
      integer :: digit
      res = ''
      do digit = 1, size(i)
        write(tmp,'(i0)') i(digit)
        res = res//trim(tmp)//' '
      enddo
      res = trim(res)
    end function
    pure function itoa_1d_i8(i) result(res)
      character(:),allocatable :: res
      integer(kind=INT64),intent(in) :: i(:)
      character(range(i)+2) :: tmp
      integer :: digit
      res = ''
      do digit = 1, size(i)
        write(tmp,'(i0)') i(digit)
        res = res//trim(tmp)//' '
      enddo
      res = trim(res)
    end function
    pure function ftoa_r32(i) result(res)
      character(:),allocatable :: res
      real(REAL32),intent(in) :: i
      character(range(i)+2) :: tmp
      write(tmp,*) i
      res = trim(tmp)
    end function
    pure function ftoa_r64(i) result(res)
      character(:),allocatable :: res
      real(REAL64),intent(in) :: i
      character(range(i)+2) :: tmp
      write(tmp,*) i
      res = trim(tmp)
    end function
    pure function ftoa_1d_r32(i) result(res)
      character(:),allocatable :: res
      real(REAL32),intent(in) :: i(:)
      character(range(i)+2) :: tmp
      integer :: digit
      res = ''
      res = ''
      do digit = 1, size(i)
        write(tmp,*) i(digit)
        res = res//trim(tmp)//' '
      enddo
      res = trim(res)
    end function

    pure function ftoa_1d_r64(i) result(res)
      character(:),allocatable :: res
      real(REAL64),intent(in) :: i(:)
      character(range(i)+2) :: tmp
      integer :: digit
      res = ''
      res = ''
      do digit = 1, size(i)
        write(tmp,*) i(digit)
        res = res//trim(tmp)//' '
      enddo
      res = trim(res)
    end function

    pure function gradient(v)
      real(ireals),intent(in) :: v(:)
      real(ireals) :: gradient(size(v)-1)
      gradient = v(2:size(v))-v(1:size(v)-1)
    end function

    pure function meanvec(v)
      real(ireals),intent(in) :: v(:)
      real(ireals) :: meanvec(size(v)-1)
      meanvec = (v(2:size(v))+v(1:size(v)-1))*.5_ireals
    end function

    !> @brief Cross product, right hand rule, a(thumb), b(pointing finger)
    pure function cross_3d_r32(a, b) result(cross_3d)
      real(REAL32), dimension(3), intent(in) :: a, b
      real(REAL32), dimension(3) :: cross_3d

      cross_3d(1) = a(2) * b(3) - a(3) * b(2)
      cross_3d(2) = a(3) * b(1) - a(1) * b(3)
      cross_3d(3) = a(1) * b(2) - a(2) * b(1)
    end function
    pure function cross_3d_r64(a, b) result(cross_3d)
      real(REAL64), dimension(3), intent(in) :: a, b
      real(REAL64), dimension(3) :: cross_3d

      cross_3d(1) = a(2) * b(3) - a(3) * b(2)
      cross_3d(2) = a(3) * b(1) - a(1) * b(3)
      cross_3d(3) = a(1) * b(2) - a(2) * b(1)
    end function

    pure function cross_2d_r32(a, b) result(cross_2d)
      real(REAL32), dimension(2), intent(in) :: a, b
      real(REAL32) :: cross_2d

      cross_2d = a(1) * b(2) - a(2) * b(1)
    end function
    pure function cross_2d_r64(a, b) result(cross_2d)
      real(REAL64), dimension(2), intent(in) :: a, b
      real(REAL64) :: cross_2d

      cross_2d = a(1) * b(2) - a(2) * b(1)
    end function

    subroutine resize_arr_int32(N, arr)
      integer(INT32), intent(in) :: N
      integer(INT32), allocatable, intent(inout) :: arr(:)
      integer(INT32), allocatable :: tmp(:)
      if(size(arr).eq.N) return
      allocate(tmp(lbound(arr,1):lbound(arr,1)+N-1))
      tmp(:) = arr(1:N)
      call move_alloc(tmp, arr)
    end subroutine
    subroutine resize_arr_int64(N, arr)
      integer(INT64), intent(in) :: N
      integer(INT64), allocatable, intent(inout) :: arr(:)
      integer(INT64), allocatable :: tmp(:)
      if(size(arr).eq.N) return
      allocate(tmp(lbound(arr,1):lbound(arr,1)+N-1))
      tmp(:) = arr(1:N)
      call move_alloc(tmp, arr)
    end subroutine

    elemental function deg2rad_r32(deg) result(r)
      real(REAL32) :: r
      real(REAL32),intent(in) :: deg
      r = deg * pi32 / 180_REAL32
    end function
    elemental function deg2rad_r64(deg) result(r)
      real(REAL64) :: r
      real(REAL64),intent(in) :: deg
      r = deg * pi64 / 180
    end function
    elemental function rad2deg_r32(rad) result(r)
      real(REAL32) :: r
      real(REAL32),intent(in) :: rad
      r = rad / pi32 * 180_REAL32
    end function
    elemental function rad2deg_r64(rad) result(r)
      real(REAL64) :: r
      real(REAL64),intent(in) :: rad
      r = rad / pi64 * 180
    end function

    pure function rmse_r32(a,b) result(rmse)
      real(REAL32) :: rmse(2)
      real(REAL32),intent(in) :: a(:),b(:)
      rmse(1) = sqrt( meanval( (a-b)**2 ) )
      rmse(2) = rmse(1)/max( meanval(b), epsilon(rmse) )
    end function
    pure function rmse_r64(a,b) result(rmse)
      real(REAL64) :: rmse(2)
      real(REAL64),intent(in) :: a(:),b(:)
      rmse(1) = sqrt( meanval( (a-b)**2 ) )
      rmse(2) = rmse(1)/max( meanval(b), epsilon(rmse) )
    end function

    pure function meanval_1d_r4(arr) result(mean)
      real(REAL32) :: mean
      real(REAL32),intent(in) :: arr(:)
      mean = sum(arr)/size(arr)
    end function
    pure function meanval_2d_r4(arr) result(mean)
      real(REAL32) :: mean
      real(REAL32),intent(in) :: arr(:,:)
      mean = sum(arr)/size(arr)
    end function
    pure function meanval_3d_r4(arr) result(mean)
      real(REAL32) :: mean
      real(REAL32),intent(in) :: arr(:,:,:)
      mean = sum(arr)/size(arr)
    end function
    pure function meanval_1d_r8(arr) result(mean)
      real(REAL64) :: mean
      real(REAL64),intent(in) :: arr(:)
      mean = sum(arr)/size(arr)
    end function
    pure function meanval_2d_r8(arr) result(mean)
      real(REAL64) :: mean
      real(REAL64),intent(in) :: arr(:,:)
      mean = sum(arr)/size(arr)
    end function
    pure function meanval_3d_r8(arr) result(mean)
      real(REAL64) :: mean
      real(REAL64),intent(in) :: arr(:,:,:)
      mean = sum(arr)/size(arr)
    end function

    elemental logical function approx_r64(a,b,precis) result(approx)
      real(REAL64),intent(in) :: a,b
      real(REAL64),intent(in),optional :: precis
      real(REAL64) :: factor
      if(present(precis) ) then
        factor = precis
      else
        factor = 10._REAL64*epsilon(b)
      endif
      if( a.lt.b-factor ) then
        approx = .False.
      elseif(a.gt.b+factor) then
        approx = .False.
      else
        approx = .True.
      endif
    end function
    elemental logical function approx_r32(a,b,precis) result(approx)
      real(REAL32),intent(in) :: a,b
      real(REAL32),intent(in),optional :: precis
      real(REAL32) :: factor
      if(present(precis) ) then
        factor = precis
      else
        factor = 10._REAL32*epsilon(b)
      endif
      if( a.le.b+factor .and. a.ge.b-factor ) then
        approx = .True.
      else
        approx = .False.
      endif
    end function
    elemental logical function rel_approx(a,b,precision)
      real(ireals),intent(in) :: a,b
      real(ireals),intent(in),optional :: precision
      real(ireals) :: factor,rel_error
      if(present(precision) ) then
        factor = precision
      else
        factor = 10*epsilon(b)
      endif
      rel_error = abs(a-b)/ max(epsilon(a), abs(a+b)/2)

      if( rel_error .lt. precision ) then
        rel_approx = .True.
      else
        rel_approx = .False.
      endif
    end function

    function mpi_logical_and(comm,lval)
      integer(mpiint),intent(in) :: comm
      logical :: mpi_logical_and
      logical,intent(in) :: lval
      integer(mpiint) :: mpierr
      call mpi_allreduce(lval, mpi_logical_and, 1_mpiint, imp_logical, MPI_LAND, comm, mpierr); call CHKERR(mpierr)
    end function
    function mpi_logical_or(comm,lval)
      integer(mpiint),intent(in) :: comm
      logical :: mpi_logical_or
      logical,intent(in) :: lval
      integer(mpiint) :: mpierr
      call mpi_allreduce(lval, mpi_logical_or, 1_mpiint, imp_logical, MPI_LOR, comm, mpierr); call CHKERR(mpierr)
    end function

    subroutine imp_allreduce_min_iintegers(comm,v,r)
      integer(mpiint),intent(in) :: comm
      integer(iintegers),intent(in) :: v
      integer(iintegers),intent(out) :: r
      integer(mpiint) :: mpierr
      call mpi_allreduce(v,r,1_mpiint,imp_iinteger, MPI_MIN, comm, mpierr); call CHKERR(mpierr)
    end subroutine
    subroutine imp_allreduce_min_ireals(comm,v,r)
      integer(mpiint),intent(in) :: comm
      real(ireals),intent(in) :: v
      real(ireals),intent(out) :: r
      integer(mpiint) :: mpierr
      call mpi_allreduce(v,r,1_mpiint,imp_ireals, MPI_MIN, comm, mpierr); call CHKERR(mpierr)
    end subroutine
    subroutine imp_allreduce_max_iintegers(comm,v,r)
      integer(mpiint),intent(in) :: comm
      integer(iintegers),intent(in) :: v
      integer(iintegers),intent(out) :: r
      integer(mpiint) :: mpierr
      call mpi_allreduce(v,r,1_mpiint,imp_iinteger, MPI_MAX, comm, mpierr); call CHKERR(mpierr)
    end subroutine
    subroutine imp_allreduce_max_ireals(comm,v,r)
      integer(mpiint),intent(in) :: comm
      real(ireals),intent(in) :: v
      real(ireals),intent(out) :: r
      integer(mpiint) :: mpierr
      call mpi_allreduce(v,r,1_mpiint,imp_ireals, MPI_MAX, comm, mpierr); call CHKERR(mpierr)
    end subroutine
    subroutine imp_allreduce_sum_ireals(comm,v,r)
      integer(mpiint),intent(in) :: comm
      real(ireals),intent(in) :: v
      real(ireals),intent(out) :: r
      integer(mpiint) :: mpierr
      call mpi_allreduce(v, r, 1_mpiint, imp_ireals, MPI_SUM, comm, mpierr); call CHKERR(mpierr)
    end subroutine
    subroutine imp_allreduce_sum_i32(comm,v,r)
      integer(mpiint),intent(in) :: comm
      integer(INT32),intent(in) :: v
      integer(INT32),intent(out) :: r
      integer(mpiint) :: mpierr
      call mpi_allreduce(v, r, 1_mpiint, imp_int4, MPI_SUM, comm, mpierr); call CHKERR(mpierr)
    end subroutine
    subroutine imp_allreduce_sum_i64(comm,v,r)
      integer(mpiint),intent(in) :: comm
      integer(INT64),intent(in) :: v
      integer(INT64),intent(out) :: r
      integer(mpiint) :: mpierr
      call mpi_allreduce(v, r, 1_mpiint, imp_int8, MPI_SUM, comm, mpierr); call CHKERR(mpierr)
    end subroutine
    subroutine imp_allreduce_mean_2d(comm,v,r)
      integer(mpiint),intent(in) :: comm
      real(ireals),intent(in) :: v(:,:)
      real(ireals),intent(out) :: r
      integer(INT64)  :: global_size
      real(ireals) :: my_avg

      call imp_allreduce_sum(comm, size(v, kind=INT64), global_size)
      my_avg = meanval(v) * size(v)
      call imp_allreduce_sum(comm, my_avg, r)
      r = r / real(global_size, kind(r))
    end subroutine
    subroutine imp_allreduce_mean_3d(comm,v,r)
      integer(mpiint),intent(in) :: comm
      real(ireals),intent(in) :: v(:,:,:)
      real(ireals),intent(out) :: r
      integer(INT64)  :: global_size
      real(ireals) :: my_avg

      call imp_allreduce_sum(comm, size(v, kind=INT64), global_size)
      my_avg = meanval(v) * size(v)
      call imp_allreduce_sum(comm, my_avg, r)
      r = r / real(global_size, kind(r))
    end subroutine
    subroutine imp_reduce_sum_r32(comm,v)
      real(REAL32),intent(inout) :: v
      integer(mpiint),intent(in) :: comm
      integer(mpiint) :: commsize, myid
      integer(mpiint) :: mpierr
      call MPI_Comm_size( comm, commsize, mpierr); call CHKERR(mpierr)
      if(commsize.le.1) return
      call MPI_Comm_rank( comm, myid, mpierr); call CHKERR(mpierr)

      if(myid.eq.0) then
        call mpi_reduce(MPI_IN_PLACE, v, 1_mpiint, imp_ireals, MPI_SUM, 0_mpiint, comm, mpierr); call CHKERR(mpierr)
      else
        call mpi_reduce(v, MPI_IN_PLACE, 1_mpiint, imp_ireals, MPI_SUM, 0_mpiint, comm, mpierr); call CHKERR(mpierr)
      endif
    end subroutine
    subroutine imp_reduce_sum_r64(comm,v)
      real(REAL64),intent(inout) :: v
      integer(mpiint),intent(in) :: comm
      integer(mpiint) :: commsize, myid
      integer(mpiint) :: mpierr
      call MPI_Comm_size( comm, commsize, mpierr); call CHKERR(mpierr)
      if(commsize.le.1) return
      call MPI_Comm_rank( comm, myid, mpierr); call CHKERR(mpierr)

      if(myid.eq.0) then
        call mpi_reduce(MPI_IN_PLACE, v, 1_mpiint, imp_ireals, MPI_SUM, 0_mpiint, comm, mpierr); call CHKERR(mpierr)
      else
        call mpi_reduce(v, MPI_IN_PLACE, 1_mpiint, imp_ireals, MPI_SUM, 0_mpiint, comm, mpierr); call CHKERR(mpierr)
      endif
    end subroutine

    subroutine imp_allgather_int_inplace(comm,v)
      integer(mpiint),intent(in) :: comm
      integer(iintegers),intent(inout) :: v(:)
      integer(mpiint) :: mpierr
      call mpi_allgather(MPI_IN_PLACE, 0_mpiint, MPI_DATATYPE_NULL, v, 1_mpiint, imp_iinteger, comm, mpierr); call CHKERR(mpierr)
    end subroutine

    subroutine  imp_bcast_logical(comm,val,sendid)
      integer(mpiint),intent(in) :: comm
      logical,intent(inout) :: val
      integer(mpiint),intent(in) :: sendid
      integer(mpiint) :: commsize
      integer(mpiint) :: mpierr
      call MPI_Comm_size( comm, commsize, mpierr); call CHKERR(mpierr)
      if(commsize.le.1) return

      call mpi_bcast(val, 1_mpiint, imp_logical, sendid, comm, mpierr); call CHKERR(mpierr)
    end subroutine
    subroutine  imp_bcast_int4(comm,val,sendid)
      integer(mpiint),intent(in) :: comm
      integer(kind=4),intent(inout) :: val
      integer(mpiint),intent(in) :: sendid
      integer(mpiint) :: commsize
      integer(mpiint) :: mpierr
      call MPI_Comm_size( comm, commsize, mpierr); call CHKERR(mpierr)
      if(commsize.le.1) return

      call mpi_bcast(val,1_mpiint,imp_int4,sendid,comm,mpierr); call CHKERR(mpierr)
    end subroutine
    subroutine  imp_bcast_int8(comm,val,sendid)
      integer(mpiint),intent(in) :: comm
      integer(kind=8),intent(inout) :: val
      integer(mpiint),intent(in) :: sendid
      integer(mpiint) :: commsize
      integer(mpiint) :: mpierr
      call MPI_Comm_size( comm, commsize, mpierr); call CHKERR(mpierr)
      if(commsize.le.1) return

      call mpi_bcast(val,1_mpiint,imp_int8,sendid,comm,mpierr); call CHKERR(mpierr)
    end subroutine
    subroutine  imp_bcast_int_1d(comm,arr,sendid)
      integer(mpiint),intent(in) :: comm
      integer(iintegers),allocatable,intent(inout) :: arr(:)
      integer(mpiint),intent(in) :: sendid
      integer(mpiint) :: myid

      integer(iintegers) :: Ntot
      integer(mpiint) :: commsize
      integer(mpiint) :: mpierr
      call MPI_Comm_size( comm, commsize, mpierr); call CHKERR(mpierr)
      if(commsize.le.1) return
      call MPI_Comm_rank( comm, myid, mpierr); call CHKERR(mpierr)

      if(sendid.eq.myid) Ntot = size(arr)
      call mpi_bcast(Ntot,1_mpiint,imp_iinteger,sendid,comm,mpierr); call CHKERR(mpierr)

      if(myid.ne.sendid) allocate( arr(Ntot) )
      call mpi_bcast(arr,size(arr),imp_iinteger,sendid,comm,mpierr); call CHKERR(mpierr)
    end subroutine
    subroutine  imp_bcast_int_2d(comm,arr,sendid)!
      integer(mpiint),intent(in) :: comm
      integer(iintegers),allocatable,intent(inout) :: arr(:,:)
      integer(mpiint),intent(in) :: sendid
      integer(mpiint) :: myid

      integer(iintegers) :: Ntot(2)
      integer(mpiint) :: commsize
      integer(mpiint) :: mpierr
      call MPI_Comm_size( comm, commsize, mpierr); call CHKERR(mpierr)
      call MPI_Comm_rank( comm, myid, mpierr); call CHKERR(mpierr)
      if(commsize.le.1) return

      if(sendid.eq.myid) Ntot = shape(arr)
      call mpi_bcast(Ntot,2_mpiint,imp_iinteger,sendid,comm,mpierr); call CHKERR(mpierr)

      if(myid.ne.sendid) allocate( arr(Ntot(1), Ntot(2)) )
      call mpi_bcast(arr,size(arr),imp_iinteger,sendid,comm,mpierr); call CHKERR(mpierr)
    end subroutine
    subroutine  imp_bcast_real(comm,val,sendid)
      integer(mpiint),intent(in) :: comm
      real(ireals),intent(inout) :: val
      integer(mpiint),intent(in) :: sendid
      integer(mpiint) :: commsize
      integer(mpiint) :: mpierr
      call MPI_Comm_size( comm, commsize, mpierr); call CHKERR(mpierr)
      if(commsize.le.1) return

      call mpi_bcast(val,1_mpiint,imp_ireals,sendid,comm,mpierr); call CHKERR(mpierr)
    end subroutine
    subroutine  imp_bcast_real_1d(comm,arr,sendid)
      integer(mpiint),intent(in) :: comm
      real(ireals),allocatable,intent(inout) :: arr(:)
      integer(mpiint),intent(in) :: sendid
      integer(mpiint) :: myid

      integer(iintegers) :: Ntot
      integer(mpiint) :: commsize
      integer(mpiint) :: mpierr
      call MPI_Comm_size( comm, commsize, mpierr); call CHKERR(mpierr)
      if(commsize.le.1) return
      call MPI_Comm_rank( comm, myid, mpierr); call CHKERR(mpierr)

      if(sendid.eq.myid) Ntot = size(arr)
      call mpi_bcast(Ntot,1_mpiint,imp_iinteger,sendid,comm,mpierr); call CHKERR(mpierr)

      if(myid.ne.sendid) allocate( arr(Ntot) )
      call mpi_bcast(arr,size(arr),imp_ireals,sendid,comm,mpierr); call CHKERR(mpierr)
    end subroutine

    subroutine  imp_bcast_real32_2d_ptr(comm,arr,sendid)
      integer(mpiint),intent(in) :: comm
      real(REAL32),pointer,intent(inout) :: arr(:,:)
      integer(mpiint),intent(in) :: sendid
      integer(mpiint) :: myid

      integer(iintegers) :: Ntot(2)
      integer(mpiint) :: commsize
      integer(mpiint) :: mpierr
      call MPI_Comm_size( comm, commsize, mpierr); call CHKERR(mpierr)
      if(commsize.le.1) return
      call MPI_Comm_rank( comm, myid, mpierr); call CHKERR(mpierr)

      if(sendid.eq.myid) Ntot = shape(arr)
      call mpi_bcast(Ntot,2_mpiint,imp_iinteger,sendid,comm,mpierr); call CHKERR(mpierr)

      if(myid.ne.sendid) allocate( arr(Ntot(1), Ntot(2)) )
      call mpi_bcast(arr,size(arr),imp_REAL32,sendid,comm,mpierr); call CHKERR(mpierr)
    end subroutine
    subroutine  imp_bcast_real64_2d_ptr(comm,arr,sendid)
      integer(mpiint),intent(in) :: comm
      real(REAL64),pointer,intent(inout) :: arr(:,:)
      integer(mpiint),intent(in) :: sendid
      integer(mpiint) :: myid

      integer(iintegers) :: Ntot(2)
      integer(mpiint) :: commsize
      integer(mpiint) :: mpierr
      call MPI_Comm_size( comm, commsize, mpierr); call CHKERR(mpierr)
      if(commsize.le.1) return
      call MPI_Comm_rank( comm, myid, mpierr); call CHKERR(mpierr)

      if(sendid.eq.myid) Ntot = shape(arr)
      call mpi_bcast(Ntot,2_mpiint,imp_iinteger,sendid,comm,mpierr); call CHKERR(mpierr)

      if(myid.ne.sendid) allocate( arr(Ntot(1), Ntot(2)) )
      call mpi_bcast(arr,size(arr),imp_REAL64,sendid,comm,mpierr); call CHKERR(mpierr)
    end subroutine
    subroutine  imp_bcast_real32_2d(comm,arr,sendid)
      integer(mpiint),intent(in) :: comm
      real(REAL32),allocatable,intent(inout) :: arr(:,:)
      integer(mpiint),intent(in) :: sendid
      integer(mpiint) :: myid

      integer(iintegers) :: Ntot(2)
      integer(mpiint) :: commsize
      integer(mpiint) :: mpierr
      call MPI_Comm_size( comm, commsize, mpierr); call CHKERR(mpierr)
      if(commsize.le.1) return
      call MPI_Comm_rank( comm, myid, mpierr); call CHKERR(mpierr)

      if(sendid.eq.myid) Ntot = shape(arr)
      call mpi_bcast(Ntot,2_mpiint,imp_iinteger,sendid,comm,mpierr); call CHKERR(mpierr)

      if(myid.ne.sendid) allocate( arr(Ntot(1), Ntot(2)) )
      call mpi_bcast(arr,size(arr),imp_REAL32,sendid,comm,mpierr); call CHKERR(mpierr)
    end subroutine
    subroutine  imp_bcast_real64_2d(comm,arr,sendid)
      integer(mpiint),intent(in) :: comm
      real(REAL64),allocatable,intent(inout) :: arr(:,:)
      integer(mpiint),intent(in) :: sendid
      integer(mpiint) :: myid

      integer(iintegers) :: Ntot(2)
      integer(mpiint) :: commsize
      integer(mpiint) :: mpierr
      call MPI_Comm_size( comm, commsize, mpierr); call CHKERR(mpierr)
      if(commsize.le.1) return
      call MPI_Comm_rank( comm, myid, mpierr); call CHKERR(mpierr)

      if(sendid.eq.myid) Ntot = shape(arr)
      call mpi_bcast(Ntot,2_mpiint,imp_iinteger,sendid,comm,mpierr); call CHKERR(mpierr)

      if(myid.ne.sendid) allocate( arr(Ntot(1), Ntot(2)) )
      call mpi_bcast(arr,size(arr),imp_REAL64,sendid,comm,mpierr); call CHKERR(mpierr)
    end subroutine
    subroutine  imp_bcast_real_3d(comm,arr,sendid)
      integer(mpiint),intent(in) :: comm
      real(ireals),allocatable,intent(inout) :: arr(:,:,:)
      integer(mpiint),intent(in) :: sendid
      integer(mpiint) :: myid

      integer(iintegers) :: Ntot(3)
      integer(mpiint) :: commsize
      integer(mpiint) :: mpierr
      call MPI_Comm_size( comm, commsize, mpierr); call CHKERR(mpierr)
      if(commsize.le.1) return
      call MPI_Comm_rank( comm, myid, mpierr); call CHKERR(mpierr)

      if(sendid.eq.myid) Ntot = shape(arr)
      call mpi_bcast(Ntot,3_mpiint,imp_iinteger,sendid,comm,mpierr); call CHKERR(mpierr)

      if(myid.ne.sendid) allocate( arr(Ntot(1), Ntot(2), Ntot(3) ) )
      call mpi_bcast(arr,size(arr),imp_ireals,sendid,comm,mpierr); call CHKERR(mpierr)
    end subroutine
    subroutine  imp_bcast_real_5d(comm,arr,sendid)
      integer(mpiint),intent(in) :: comm
      real(ireals),allocatable,intent(inout) :: arr(:,:,:,:,:)
      integer(mpiint),intent(in) :: sendid
      integer(mpiint) :: myid

      integer(iintegers) :: Ntot(5)
      integer(mpiint) :: commsize
      integer(mpiint) :: mpierr
      call MPI_Comm_size(comm, commsize, mpierr); call CHKERR(mpierr)
      if(commsize.le.1) return
      call MPI_Comm_rank( comm, myid, mpierr); call CHKERR(mpierr)

      if(sendid.eq.myid) Ntot = shape(arr)
      call mpi_bcast(Ntot,5_mpiint,imp_iinteger,sendid,comm,mpierr); call CHKERR(mpierr)

      if(myid.ne.sendid) allocate( arr(Ntot(1), Ntot(2), Ntot(3), Ntot(4), Ntot(5) ) )
      call mpi_bcast(arr,size(arr),imp_ireals,sendid,comm,mpierr); call CHKERR(mpierr)
    end subroutine

    elemental subroutine delta_scale_r32(kabs, ksca, g, opt_f, max_g)
      real(REAL32),intent(inout) :: kabs, ksca, g
      real(REAL32),intent(in), optional :: opt_f, max_g
      real(REAL32) :: dtau, w0, f

      if(present(opt_f)) then
        f = opt_f
      else
        f = g**2
      endif

      if(present(max_g)) then
        if(g.lt.max_g) return
        f = (max_g - g) / (max_g - 1._REAL32)
      endif

      dtau = max( kabs+ksca, epsilon(dtau) )
      w0   = ksca/dtau
      g    = g

      call delta_scale_optprop( dtau, w0, g, f)

      kabs= dtau * (1._REAL32-w0)
      ksca= dtau * w0
    end subroutine
    elemental subroutine delta_scale_r64(kabs, ksca, g, opt_f, max_g)
      real(REAL64),intent(inout) :: kabs, ksca, g
      real(REAL64),intent(in), optional :: opt_f, max_g
      real(REAL64) :: dtau, w0, f

      if(present(opt_f)) then
        f = opt_f
      else
        f = g**2
      endif

      if(present(max_g)) then
        if(g.lt.max_g) return
        f = (max_g - g) / (max_g - 1._REAL64)
      endif

      dtau = max( kabs+ksca, epsilon(dtau) )
      w0   = ksca/dtau
      g    = g

      call delta_scale_optprop( dtau, w0, g, f)

      kabs= dtau * (1._REAL64-w0)
      ksca= dtau * w0
    end subroutine
    elemental subroutine delta_scale_optprop_r32(dtau, w0, g, f)
      real(REAL32), intent(inout) :: dtau,w0,g
      real(REAL32), intent(in) :: f

      g = min( g, 1._REAL32-epsilon(g)*10)
      dtau = dtau * ( 1._REAL32 - w0 * f )
      g    = ( g - f ) / ( 1._REAL32 - f )
      w0   = w0 * ( 1._REAL32 - f ) / ( 1._REAL32 - f * w0 )
    end subroutine
    elemental subroutine delta_scale_optprop_r64(dtau, w0, g, f)
      real(REAL64), intent(inout) :: dtau,w0,g
      real(REAL64), intent(in) :: f

      g = min( g, 1._REAL64-epsilon(g)*10)
      dtau = dtau * ( 1._REAL64 - w0 * f )
      g    = ( g - f ) / ( 1._REAL64 - f )
      w0   = w0 * ( 1._REAL64 - f ) / ( 1._REAL64 - f * w0 )
    end subroutine

    function cumsum_ireals(arr) result(cumsum)
      real(ireals),intent(in) :: arr(:)
      real(ireals) :: cumsum(size(arr))
      integer :: i
      cumsum(1) = arr(1)
      do i=2,size(arr)
        cumsum(i) = cumsum(i-1) + arr(i)
      enddo
    end function
    function cumsum_iintegers(arr) result(cumsum)
      integer(iintegers),intent(in) :: arr(:)
      integer(iintegers) :: cumsum(size(arr))
      integer :: i
      cumsum(1) = arr(1)
      do i=2,size(arr)
        cumsum(i) = cumsum(i-1) + arr(i)
      enddo
    end function

    ! From Numerical Recipes: cumulative product on an array, with optional multiplicative seed.
    pure recursive function cumprod_ireals(arr,seed) result(ans)
      real(ireals), dimension(:), intent(in) :: arr
      real(ireals), optional, intent(in) :: seed
      real(ireals), dimension(size(arr)) :: ans
      integer(iintegers) :: n,j
      real(ireals) :: sd
      n=size(arr)
      if (n == 0) return
      sd = 1
      if (present(seed)) sd=seed
      ans(1)=arr(1)*sd
      if (n < npar_cumprod) then
        do j=2,n
          ans(j)=ans(j-1)*arr(j)
        end do
      else
        ans(2:n:2)=cumprod(arr(2:n:2)*arr(1:n-1:2),sd)
        ans(3:n:2)=ans(2:n-1:2)*arr(3:n:2)
      end if
    end function
    pure recursive function cumprod_iintegers(arr,seed) result(ans)
      integer(iintegers), dimension(:), intent(in) :: arr
      integer(iintegers), optional, intent(in) :: seed
      integer(iintegers), dimension(size(arr)) :: ans
      integer(iintegers) :: n,j
      integer(iintegers) :: sd
      n=size(arr)
      if (n == 0) return
      sd = 1
      if (present(seed)) sd=seed
      ans(1)=arr(1)*sd
      if (n < npar_cumprod) then
        do j=2,n
          ans(j)=ans(j-1)*arr(j)
        end do
      else
        ans(2:n:2)=cumprod(arr(2:n:2)*arr(1:n-1:2),sd)
        ans(3:n:2)=ans(2:n-1:2)*arr(3:n:2)
      end if
    end function

    subroutine read_ascii_file_2d(filename, arr, ncolumns, skiplines, ierr)
      character(len=*),intent(in) :: filename
      integer(iintegers),intent(in) :: ncolumns
      integer(iintegers),intent(in),optional :: skiplines

      real(ireals),allocatable,intent(out) :: arr(:,:)

      integer(mpiint) :: ierr

      real :: line(ncolumns)

      integer(iintegers) :: unit, nlines, i, io
      logical :: file_exists=.False.

      ierr=0
      inquire(file=filename, exist=file_exists)

      if(.not.file_exists) then
        print *,'File ',trim(filename), 'does not exist!'
        ierr=1
        return
      endif

      open(newunit=unit, file=filename)
      if(present(skiplines)) then
        do i=1,skiplines
          read(unit,*)
        enddo
      endif

      nlines = 0
      do
        read(unit, *, iostat=io) line
        !print *,'line',line
        if (io/=0) exit
        nlines = nlines + 1
      end do

      rewind(unit)
      if(present(skiplines)) then
        do i=1,skiplines
          read(unit,*)
        enddo
      endif

      allocate(arr(nlines,ncolumns))

      do i=1,nlines
        read(unit, *, iostat=io) line
        arr(i,:) = line
      end do

      close(unit)
      print *,'I read ',nlines,'lines'
    end subroutine


    subroutine reorder_mpi_comm(icomm, Nrank_x, Nrank_y, new_comm)
      integer(mpiint), intent(in) :: icomm
      integer(mpiint), intent(out) :: new_comm
      integer(mpiint) :: Nrank_x, Nrank_y

      ! This is the code snippet from Petsc FAQ to change from PETSC (C) domain splitting to MPI(Fortran) domain splitting
      ! the numbers of processors per direction are (int) x_procs, y_procs, z_procs respectively
      ! (no parallelization in direction 'dir' means dir_procs = 1)

      integer(mpiint) :: x,y
      integer(mpiint) :: orig_id, petsc_id ! id according to fortran decomposition

      integer(mpiint) :: mpierr
      call MPI_COMM_RANK( icomm, orig_id, mpierr ); call CHKERR(mpierr)

      ! calculate coordinates of cpus in MPI ordering:
      x = int(orig_id) / Nrank_y
      y = modulo(orig_id ,Nrank_y)

      ! set new rank according to PETSc ordering:
      petsc_id = y*Nrank_x + x

      ! create communicator with new ranks according to PETSc ordering:
      call MPI_Comm_split(icomm, 1_mpiint, petsc_id, new_comm, mpierr)

      !print *,'Reordering communicator'
      !print *,'setup_petsc_comm: MPI_COMM_WORLD',orig_id,'calc_id',petsc_id
    end subroutine

    pure function compute_normal_3d_r32(p1,p2,p3) result(compute_normal_3d)
      ! for a triangle p1, p2, p3, if the vector U = p2 - p1 and the vector V = p3 - p1
      ! then the normal (right hand rotation)
      ! N = U X V and can be calculated by:
      real(REAL32), intent(in) :: p1(:), p2(:), p3(:)
      real(REAL32) :: compute_normal_3d(size(p1))
      real(REAL32) :: U(3), V(3)

      U = p2-p1
      V = p3-p1

      compute_normal_3d = cross_3d(U,V)

      compute_normal_3d = compute_normal_3d / norm2(compute_normal_3d)
    end function
    pure function compute_normal_3d_r64(p1,p2,p3) result(compute_normal_3d)
      ! for a triangle p1, p2, p3, if the vector U = p2 - p1 and the vector V = p3 - p1
      ! then the normal (right hand rotation)
      ! N = U X V and can be calculated by:
      real(REAL64), intent(in) :: p1(:), p2(:), p3(:)
      real(REAL64) :: compute_normal_3d(size(p1))
      real(REAL64) :: U(size(p1)), V(size(p1))

      U = p2-p1
      V = p3-p1

      compute_normal_3d = cross_3d(U,V)

      compute_normal_3d = compute_normal_3d / norm2(compute_normal_3d)
    end function

    pure function determine_normal_direction(normal, center_face, center_cell)
      ! return 1 if normal is pointing towards cell_center, -1 if its pointing
      ! away from it
      real(ireals), intent(in) :: normal(3), center_face(3), center_cell(3)
      integer(iintegers) :: determine_normal_direction
      real(ireals) :: dot
      dot = dot_product(normal, center_cell - center_face)
      determine_normal_direction = int(sign(one, dot), kind=iintegers)
    end function

    !> @brief For local azimuth and zenith angles, return the local cartesian vectors phi azimuth, theta zenith angles, angles are input in degrees.
    !> @details theta == 0 :: z = -1, i.e. downward
    !> @details azimuth == 0 :: vector going toward minus y, i.e. sun shines from the north
    !> @details azimuth == 90 :: vector going toward minus x, i.e. sun shines from the east
    pure function spherical_2_cartesian_r32(phi, theta, r) result(spherical_2_cartesian)
      real(real32), intent(in) :: phi, theta
      real(real32), intent(in), optional :: r

      real(real32) :: spherical_2_cartesian(3)

      spherical_2_cartesian(1) = -sin(deg2rad(theta)) * sin(deg2rad(phi))
      spherical_2_cartesian(2) = -sin(deg2rad(theta)) * cos(deg2rad(phi))
      spherical_2_cartesian(3) = -cos(deg2rad(theta))

      if(present(r)) spherical_2_cartesian = spherical_2_cartesian*r
    end function
    pure function spherical_2_cartesian_r64(phi, theta, r) result(spherical_2_cartesian)
      real(real64), intent(in) :: phi, theta
      real(real64), intent(in), optional :: r

      real(real64) :: spherical_2_cartesian(3)

      spherical_2_cartesian(1) = -sin(deg2rad(theta)) * sin(deg2rad(phi))
      spherical_2_cartesian(2) = -sin(deg2rad(theta)) * cos(deg2rad(phi))
      spherical_2_cartesian(3) = -cos(deg2rad(theta))

      if(present(r)) spherical_2_cartesian = spherical_2_cartesian*r
    end function

    !> @brief returns the angle between two not necessarily normed vectors. Result is in radians
    !TODO: refactor in two functions, one for normed vecs and one for unnormed
    function angle_between_two_vec_r32(p1, p2) result(angle_between_two_vec)
      real(REAL32),intent(in) :: p1(:), p2(:)
      real(REAL32) :: angle_between_two_vec
      real(REAL32) :: n1, n2, dp
      real(REAL32), parameter :: eps = 1._REAL32 + sqrt(epsilon(eps))
      if(all(approx(p1,p2))) then ! if p1 and p2 are the same, just return
        angle_between_two_vec = 0
        return
      endif
      n1 = norm2(p1)
      n2 = norm2(p2)
      if(any(approx([n1,n2], 0._REAL32))) then
        call CHKWARN(1_mpiint, 'FPE exception angle_between_two_vec :: '//ftoa(p1)//' : '//ftoa(p2))
      endif

      dp = dot_product(p1/n1, p2/n2)
      if(dp.gt.eps.or.dp.lt.-eps) print *,'FPE exception angle_between_two_vec :: dp wrong', dp
      dp = max( min(dp, 1._REAL32), -1._REAL32)
      angle_between_two_vec = acos(dp)
    end function
    function angle_between_two_vec_r64(p1, p2) result(angle_between_two_vec)
      real(REAL64),intent(in) :: p1(:), p2(:)
      real(REAL64) :: angle_between_two_vec
      real(REAL64) :: n1, n2, dp
      real(REAL64), parameter :: eps = 1._REAL64 + sqrt(epsilon(eps))
      if(all(approx(p1,p2))) then ! if p1 and p2 are the same, just return
        angle_between_two_vec = 0
        return
      endif
      n1 = norm2(p1)
      n2 = norm2(p2)
      if(any(approx([n1,n2], 0._REAL64))) then
        call CHKWARN(1_mpiint, 'FPE exception angle_between_two_vec :: '//ftoa(p1)//' : '//ftoa(p2))
      endif

      dp = dot_product(p1/n1, p2/n2)
      if(dp.gt.eps.or.dp.lt.-eps) print *,'FPE exception angle_between_two_vec :: dp wrong', dp
      dp = max( min(dp, 1._REAL64), -1._REAL64)
      angle_between_two_vec = acos(dp)
    end function

    !> @brief Determine Edge length/ distance between two points
    function distance_r32(p1,p2) result(distance)
      real(REAL32), intent(in) :: p1(:), p2(:)
      real(REAL32) :: distance
      integer(iintegers) :: i
      distance = 0
      do i=1,size(p1)
        distance = distance + (p2(i) - p1(i))**2
      enddo
      distance = sqrt(distance)
    end function
    function distance_r64(p1,p2) result(distance)
      real(REAL64), intent(in) :: p1(:), p2(:)
      real(REAL64) :: distance
      integer(iintegers) :: i
      distance = 0
      do i=1,size(p1)
        distance = distance + (p2(i) - p1(i))**2
      enddo
      distance = sqrt(distance)
    end function

    !> @brief Use Herons Formula to determine the area of a triangle given the 3 edge lengths
    function triangle_area_by_edgelengths_r32(e1,e2,e3) result(triangle_area_by_edgelengths)
      real(REAL32), intent(in) :: e1,e2,e3
      real(REAL32) :: triangle_area_by_edgelengths
      real(REAL32) :: p
      p = (e1+e2+e3)/2
      triangle_area_by_edgelengths = sqrt(p*(p-e1)*(p-e2)*(p-e3))
    end function
    function triangle_area_by_edgelengths_r64(e1,e2,e3) result(triangle_area_by_edgelengths)
      real(REAL64), intent(in) :: e1,e2,e3
      real(REAL64) :: triangle_area_by_edgelengths
      real(REAL64) :: p
      p = (e1+e2+e3)/2
      triangle_area_by_edgelengths = sqrt(p*(p-e1)*(p-e2)*(p-e3))
    end function

    !> @brief Use Herons Formula to determine the area of a triangle given the 3 vertices
    function triangle_area_by_vertices_r32(v1,v2,v3) result(triangle_area_by_vertices)
      real(REAL32), intent(in) :: v1(:),v2(:),v3(:)
      real(REAL32) :: triangle_area_by_vertices
      real(REAL32) :: e1, e2, e3
      e1 = distance(v1,v2)
      e2 = distance(v2,v3)
      e3 = distance(v3,v1)
      triangle_area_by_vertices = triangle_area_by_edgelengths(e1,e2,e3)
    end function
    function triangle_area_by_vertices_r64(v1,v2,v3) result(triangle_area_by_vertices)
      real(REAL64), intent(in) :: v1(:),v2(:),v3(:)
      real(REAL64) :: triangle_area_by_vertices
      real(REAL64) :: e1, e2, e3
      e1 = distance(v1,v2)
      e2 = distance(v2,v3)
      e3 = distance(v3,v1)
      triangle_area_by_vertices = triangle_area_by_edgelengths(e1,e2,e3)
    end function

    !> @brief determine distance where a photon p intersects with a plane
    !> @details inputs are the location and direction of a photon aswell as the origin and surface normal of the plane
    pure function hit_plane(p_loc, p_dir, po, pn)
      real(ireals) :: hit_plane
      real(ireals),intent(in) :: p_loc(3), p_dir(3)
      real(ireals),intent(in) :: po(3), pn(3)
      real(ireals) :: discr
      discr = dot_product(p_dir,pn)
      if( ( discr.le. epsilon(discr) ) .and. ( discr.gt.-epsilon(discr)  ) ) then
        hit_plane = huge(hit_plane)
      else
        hit_plane = dot_product(po-p_loc, pn) / discr
      endif
    end function

    !> @brief determine if point is inside a rectangle p1,p2,p3
    function pnt_in_rectangle_r32(p1,p2,p3, p) result(pnt_in_rectangle)
      real(REAL32), intent(in), dimension(2) :: p1,p2,p3, p
      logical :: pnt_in_rectangle
      real(REAL32),parameter :: eps = epsilon(eps), eps2 = sqrt(eps)

      ! check for rectangular bounding box
      if ( p(1).lt.minval([p1(1),p2(1),p3(1)])-eps2 .or. p(1).gt.maxval([p1(1),p2(1),p3(1)])+eps2 ) then ! outside of xrange
        pnt_in_rectangle=.False.
        return
      endif
      if ( p(2).lt.minval([p1(2),p2(2),p3(2)])-eps2 .or. p(2).gt.maxval([p1(2),p2(2),p3(2)])+eps2 ) then ! outside of yrange
        pnt_in_rectangle=.False.
        return
      endif
      pnt_in_rectangle=.True.
    end function
    function pnt_in_rectangle_r64(p1,p2,p3, p) result(pnt_in_rectangle)
      real(REAL64), intent(in), dimension(2) :: p1,p2,p3, p
      logical :: pnt_in_rectangle
      real(REAL64),parameter :: eps = epsilon(eps), eps2 = sqrt(eps)

      ! check for rectangular bounding box
      if ( p(1).lt.minval([p1(1),p2(1),p3(1)])-eps2 .or. p(1).gt.maxval([p1(1),p2(1),p3(1)])+eps2 ) then ! outside of xrange
        pnt_in_rectangle=.False.
        return
      endif
      if ( p(2).lt.minval([p1(2),p2(2),p3(2)])-eps2 .or. p(2).gt.maxval([p1(2),p2(2),p3(2)])+eps2 ) then ! outside of yrange
        pnt_in_rectangle=.False.
        return
      endif
      pnt_in_rectangle=.True.
    end function

    !> @brief determine if point is inside a triangle p1,p2,p3
    function pnt_in_triangle_r32(p1,p2,p3, p) result(pnt_in_triangle)
      real(REAL32), intent(in), dimension(2) :: p1,p2,p3, p
      logical :: pnt_in_triangle
      real(REAL32),parameter :: eps = epsilon(eps), eps2 = 100*eps
      real(REAL32) :: a, b, c, edge_dist

      logical, parameter :: ldebug=.False.

      pnt_in_triangle = pnt_in_rectangle(p1,p2,p3, p)
      if(ldebug) print *,'pnt_in_triangle::pnt in rectangle:', p1, p2, p3, 'p', p, '::', pnt_in_triangle
      if (.not.pnt_in_triangle) then ! if pnt is not in rectangle, it is not in triangle!
        ! Then check for sides
        a = ((p2(2)- p3(2))*(p(1) - p3(1)) + (p3(1) - p2(1))*(p(2) - p3(2))) / ((p2(2) - p3(2))*(p1(1) - p3(1)) + (p3(1) - p2(1))*(p1(2) - p3(2)))
        b = ((p3(2) - p1(2))*(p(1) - p3(1)) + (p1(1) - p3(1))*(p(2) - p3(2))) / ((p2(2) - p3(2))*(p1(1) - p3(1)) + (p3(1) - p2(1))*(p1(2) - p3(2)))
        c = 1._REAL32 - (a + b)

        pnt_in_triangle = all([a,b,c].ge.0._REAL32)
        if(ldebug) print *,'pnt_in_triangle::1st check:', a, b, c, '::', pnt_in_triangle
      endif

      if(.not.pnt_in_triangle) then
        pnt_in_triangle = pnt_in_triangle_convex_hull(p1,p2,p3, p)
        if(ldebug) print *,'pnt_in_triangle::convex hull:', pnt_in_triangle
      endif

      if(.not.pnt_in_triangle) then ! Compute distances to each edge and allow the check to be positive if the distance is small
        edge_dist = minval(distances_to_triangle_edges(p1,p2,p3,p))
        if(edge_dist.le.eps) then
          if((p(1).lt.min(p1(1),p2(1))) .or. (p(1).gt.max(p1(1),p2(1)) )) then
            ! is on line but ouside of segment
            continue
          else
            pnt_in_triangle=.True.
          endif
          if(ldebug) print *,'pnt_in_triangle edgedist:',edge_dist,'=>', pnt_in_triangle
        endif
      endif

      if(ldebug.and..not.pnt_in_triangle) print *,'pnt_in_triangle final:', pnt_in_triangle,'::',a,b,c,':',p, &
        'edgedist',distances_to_triangle_edges(p1,p2,p3,p),distances_to_triangle_edges(p1,p2,p3,p).le.eps
    end function
    function pnt_in_triangle_r64(p1,p2,p3, p) result(pnt_in_triangle)
      real(REAL64), intent(in), dimension(2) :: p1,p2,p3, p
      logical :: pnt_in_triangle
      real(REAL64),parameter :: eps = epsilon(eps), eps2 = 100*eps
      real(REAL64) :: a, b, c, edge_dist

      logical, parameter :: ldebug=.False.

      pnt_in_triangle = pnt_in_rectangle(p1,p2,p3, p)
      if(ldebug) print *,'pnt_in_triangle::pnt in rectangle:', p1, p2, p3, 'p', p, '::', pnt_in_triangle
      if (.not.pnt_in_triangle) then ! if pnt is not in rectangle, it is not in triangle!
        ! Then check for sides
        a = ((p2(2)- p3(2))*(p(1) - p3(1)) + (p3(1) - p2(1))*(p(2) - p3(2))) / ((p2(2) - p3(2))*(p1(1) - p3(1)) + (p3(1) - p2(1))*(p1(2) - p3(2)))
        b = ((p3(2) - p1(2))*(p(1) - p3(1)) + (p1(1) - p3(1))*(p(2) - p3(2))) / ((p2(2) - p3(2))*(p1(1) - p3(1)) + (p3(1) - p2(1))*(p1(2) - p3(2)))
        c = one - (a + b)

        pnt_in_triangle = all([a,b,c].ge.zero)
        if(ldebug) print *,'pnt_in_triangle::1st check:', a, b, c, '::', pnt_in_triangle
      endif

      if(.not.pnt_in_triangle) then
        pnt_in_triangle = pnt_in_triangle_convex_hull(p1,p2,p3, p)
        if(ldebug) print *,'pnt_in_triangle::convex hull:', pnt_in_triangle
      endif

      if(.not.pnt_in_triangle) then ! Compute distances to each edge and allow the check to be positive if the distance is small
        edge_dist = minval(distances_to_triangle_edges(p1,p2,p3,p))
        if(edge_dist.le.eps) then
          if((p(1).lt.min(p1(1),p2(1))) .or. (p(1).gt.max(p1(1),p2(1)) )) then
            ! is on line but ouside of segment
            continue
          else
            pnt_in_triangle=.True.
          endif
          if(ldebug) print *,'pnt_in_triangle edgedist:',edge_dist,'=>', pnt_in_triangle
        endif
      endif

      if(ldebug.and..not.pnt_in_triangle) print *,'pnt_in_triangle final:', pnt_in_triangle,'::',a,b,c,':',p, &
        'edgedist',distances_to_triangle_edges(p1,p2,p3,p),distances_to_triangle_edges(p1,p2,p3,p).le.eps
    end function

    function pnt_in_triangle_convex_hull_r32(p1,p2,p3, p) result(pnt_in_triangle_convex_hull)
      real(REAL32), intent(in), dimension(2) :: p1,p2,p3, p
      logical :: pnt_in_triangle_convex_hull
      real(REAL32), dimension(2) :: v0, v1, v2
      real(REAL32) :: a,b

      v0 = p1
      v1 = p2-p1
      v2 = p3-p1

      a =  (cross_2d(p, v2) - cross_2d(v0, v2)) / cross_2d(v1, v2)
      b = -(cross_2d(p, v1) - cross_2d(v0, v1)) / cross_2d(v1, v2)

      pnt_in_triangle_convex_hull = all([a,b].ge.0._REAL32) .and. (a+b).le.1._REAL32

      !print *,'points',p1,p2,p3,'::',p
      !print *,'a,b',a,b,'::',a+b, '::>',pnt_in_triangle_convex_hull
    end function
    function pnt_in_triangle_convex_hull_r64(p1,p2,p3, p) result(pnt_in_triangle_convex_hull)
      real(REAL64), intent(in), dimension(2) :: p1,p2,p3, p
      logical :: pnt_in_triangle_convex_hull
      real(REAL64), dimension(2) :: v0, v1, v2
      real(REAL64) :: a,b

      v0 = p1
      v1 = p2-p1
      v2 = p3-p1

      a =  (cross_2d(p, v2) - cross_2d(v0, v2)) / cross_2d(v1, v2)
      b = -(cross_2d(p, v1) - cross_2d(v0, v1)) / cross_2d(v1, v2)

      pnt_in_triangle_convex_hull = all([a,b].ge.0._REAL64) .and. (a+b).le.1._REAL64

      !print *,'points',p1,p2,p3,'::',p
      !print *,'a,b',a,b,'::',a+b, '::>',pnt_in_triangle_convex_hull
    end function

    pure function distances_to_triangle_edges_r32(p1,p2,p3,p) result(distances_to_triangle_edges)
      real(REAL32), intent(in), dimension(2) :: p1,p2,p3, p
      real(REAL32) :: distances_to_triangle_edges(3)
      distances_to_triangle_edges(1) = distance_to_edge(p1,p2,p)
      distances_to_triangle_edges(2) = distance_to_edge(p2,p3,p)
      distances_to_triangle_edges(3) = distance_to_edge(p1,p3,p)
    end function
    pure function distances_to_triangle_edges_r64(p1,p2,p3,p) result(distances_to_triangle_edges)
      real(REAL64), intent(in), dimension(2) :: p1,p2,p3, p
      real(REAL64) :: distances_to_triangle_edges(3)
      distances_to_triangle_edges(1) = distance_to_edge(p1,p2,p)
      distances_to_triangle_edges(2) = distance_to_edge(p2,p3,p)
      distances_to_triangle_edges(3) = distance_to_edge(p1,p3,p)
    end function

    pure function distance_to_edge_r32(p1,p2,p) result(distance_to_edge)
      real(REAL32), intent(in), dimension(2) :: p1,p2, p
      real(REAL32) :: distance_to_edge

      distance_to_edge = abs( (p2(2)-p1(2))*p(1) - (p2(1)-p1(1))*p(2) + p2(1)*p1(2) - p2(2)*p1(1) ) / norm2(p2-p1)
    end function
    pure function distance_to_edge_r64(p1,p2,p) result(distance_to_edge)
      real(REAL64), intent(in), dimension(2) :: p1,p2, p
      real(REAL64) :: distance_to_edge

      distance_to_edge = abs( (p2(2)-p1(2))*p(1) - (p2(1)-p1(1))*p(2) + p2(1)*p1(2) - p2(2)*p1(1) ) / norm2(p2-p1)
    end function

      pure function rotate_angle_x_r32(v,angle) result(rotate_angle_x)
        ! left hand rule
        real(REAL32) :: rotate_angle_x(3)
        real(REAL32),intent(in) :: v(3), angle
        real(REAL32) :: M(3,3),s,c
        s=sin(deg2rad(angle))
        c=cos(deg2rad(angle))

        M(1,:)=[1._REAL32 ,0._REAL32 ,0._REAL32]
        M(2,:)=[0._REAL32, c   , s  ]
        M(3,:)=[0._REAL32,-s   , c  ]

        rotate_angle_x = matmul(M,v)
      end function
      pure function rotate_angle_x_r64(v,angle) result(rotate_angle_x)
        ! left hand rule
        real(REAL64) :: rotate_angle_x(3)
        real(REAL64),intent(in) :: v(3), angle
        real(REAL64) :: M(3,3),s,c
        s=sin(deg2rad(angle))
        c=cos(deg2rad(angle))

        M(1,:)=[1._REAL64 ,0._REAL64 ,0._REAL64]
        M(2,:)=[0._REAL64, c   , s  ]
        M(3,:)=[0._REAL64,-s   , c  ]

        rotate_angle_x = matmul(M,v)
      end function
      pure function rotate_angle_y_r32(v,angle) result(rotate_angle_y)
        ! left hand rule
        real(REAL32) :: rotate_angle_y(3)
        real(REAL32),intent(in) :: v(3), angle
        real(REAL32) :: M(3,3),s,c
        s=sin(deg2rad(angle))
        c=cos(deg2rad(angle))

        M(1,:)=[ c  ,0._REAL32 , -s ]
        M(2,:)=[0._REAL32, 1._REAL32 ,0._REAL32]
        M(3,:)=[ s  , 0._REAL32, c  ]

        rotate_angle_y = matmul(M,v)
      end function
      pure function rotate_angle_y_r64(v,angle) result(rotate_angle_y)
        ! left hand rule
        real(REAL64) :: rotate_angle_y(3)
        real(REAL64),intent(in) :: v(3), angle
        real(REAL64) :: M(3,3),s,c
        s=sin(deg2rad(angle))
        c=cos(deg2rad(angle))

        M(1,:)=[ c  ,0._REAL64 , -s ]
        M(2,:)=[0._REAL64, 1._REAL64 ,0._REAL64]
        M(3,:)=[ s  , 0._REAL64, c  ]

        rotate_angle_y = matmul(M,v)
      end function
      pure function rotate_angle_z_r32(v,angle) result(rotate_angle_z)
        ! left hand rule
        real(REAL32) :: rotate_angle_z(3)
        real(REAL32),intent(in) :: v(3), angle
        real(REAL32) :: M(3,3),s,c
        s=sin(deg2rad(angle))
        c=cos(deg2rad(angle))

        M(1,:)=[ c  , s   ,0._REAL32]
        M(2,:)=[-s  , c   ,0._REAL32]
        M(3,:)=[0._REAL32, 0._REAL32, 1._REAL32]

        rotate_angle_z = matmul(M,v)
      end function
      pure function rotate_angle_z_r64(v,angle) result(rotate_angle_z)
        ! left hand rule
        real(REAL64) :: rotate_angle_z(3)
        real(REAL64),intent(in) :: v(3), angle
        real(REAL64) :: M(3,3),s,c
        s=sin(deg2rad(angle))
        c=cos(deg2rad(angle))

        M(1,:)=[ c  , s   ,0._REAL64]
        M(2,:)=[-s  , c   ,0._REAL64]
        M(3,:)=[0._REAL64, 0._REAL64, 1._REAL64]

        rotate_angle_z = matmul(M,v)
      end function

    ! https://en.wikipedia.org/wiki/Rotation_matrix#General_rotations
    pure function rotation_matrix_around_axis_vec(angle, rot_axis) result(M)
      ! left hand rule
      real(ireals) :: M(3,3)
      real(ireals),intent(in) :: angle, rot_axis(3)
      real(ireals) :: s,c,u(3),omc
      u = rot_axis / norm2(rot_axis)
      s=sin(angle)
      c=cos(angle)
      omc = 1._ireals - c

      M(1,:)=[u(1)*u(1)*omc + c     , u(1)*u(2)*omc - u(3)*s, u(1)*u(3)*omc + u(2)*s]
      M(2,:)=[u(2)*u(1)*omc + u(3)*s, u(2)*u(2)*omc + c     , u(2)*U(3)*omc - u(1)*s]
      M(3,:)=[u(3)*u(1)*omc - u(2)*s, u(3)*u(2)*omc + u(1)*s, u(3)*u(3)*omc + c     ]
    end function

    ! the resulting matrix will transform a vector from world coords into the given new coord system
    pure function rotation_matrix_world_to_local_basis(ex, ey, ez) result(M)
      real(ireals), dimension(3), intent(in) :: ex, ey, ez
      real(ireals), dimension(3), parameter :: kx=[1,0,0], ky=[0,1,0], kz=[0,0,1]
      real(ireals), dimension(3,3) :: M
      M(1,1) = dot_product(ex, kx)
      M(1,2) = dot_product(ex, ky)
      M(1,3) = dot_product(ex, kz)
      M(2,1) = dot_product(ey, kx)
      M(2,2) = dot_product(ey, ky)
      M(2,3) = dot_product(ey, kz)
      M(3,1) = dot_product(ez, kx)
      M(3,2) = dot_product(ez, ky)
      M(3,3) = dot_product(ez, kz)
    end function

    ! the resulting matrix will transform a vector from the given coord system into the world coordinate system
    pure function rotation_matrix_local_basis_to_world_r32(ex, ey, ez) result(M)
      real(real32), dimension(3), intent(in) :: ex, ey, ez
      real(real32), dimension(3), parameter :: kx=[1,0,0], ky=[0,1,0], kz=[0,0,1]
      real(real32), dimension(3,3) :: M
      M(1,1) = dot_product(kx, ex)
      M(2,1) = dot_product(ky, ex)
      M(3,1) = dot_product(kz, ex)
      M(1,2) = dot_product(kx, ey)
      M(2,2) = dot_product(ky, ey)
      M(3,2) = dot_product(kz, ey)
      M(1,3) = dot_product(kx, ez)
      M(2,3) = dot_product(ky, ez)
      M(3,3) = dot_product(kz, ez)
    end function
    pure function rotation_matrix_local_basis_to_world_r64(ex, ey, ez) result(M)
      real(real64), dimension(3), intent(in) :: ex, ey, ez
      real(real64), dimension(3), parameter :: kx=[1,0,0], ky=[0,1,0], kz=[0,0,1]
      real(real64), dimension(3,3) :: M
      M(1,1) = dot_product(kx, ex)
      M(2,1) = dot_product(ky, ex)
      M(3,1) = dot_product(kz, ex)
      M(1,2) = dot_product(kx, ey)
      M(2,2) = dot_product(ky, ey)
      M(3,2) = dot_product(kz, ey)
      M(1,3) = dot_product(kx, ez)
      M(2,3) = dot_product(ky, ez)
      M(3,3) = dot_product(kz, ez)
    end function

    ! https://www.maplesoft.com/support/help/maple/view.aspx?path=MathApps%2FProjectionOfVectorOntoPlane
    pure function vec_proj_on_plane(v, plane_normal)
      real(ireals), dimension(3), intent(in) :: v, plane_normal
      real(ireals) :: vec_proj_on_plane(3)
      vec_proj_on_plane = v - dot_product(v, plane_normal) * plane_normal  / norm2(plane_normal)**2
    end function

    pure function get_arg_logical(default_value, opt_arg) result(arg)
      logical :: arg
      logical, intent(in) :: default_value
      logical, intent(in), optional :: opt_arg
      if(present(opt_arg)) then
        arg = opt_arg
      else
        arg = default_value
      endif
    end function
    pure function get_arg_i32(default_value, opt_arg) result(arg)
      integer(INT32) :: arg
      integer(INT32), intent(in) :: default_value
      integer(INT32), intent(in), optional :: opt_arg
      if(present(opt_arg)) then
        arg = opt_arg
      else
        arg = default_value
      endif
    end function
    pure function get_arg_i64(default_value, opt_arg) result(arg)
      integer(INT64) :: arg
      integer(INT64), intent(in) :: default_value
      integer(INT64), intent(in), optional :: opt_arg
      if(present(opt_arg)) then
        arg = opt_arg
      else
        arg = default_value
      endif
    end function
    pure function get_arg_real32(default_value, opt_arg) result(arg)
      real(REAL32) :: arg
      real(REAL32), intent(in) :: default_value
      real(REAL32), intent(in), optional :: opt_arg
      if(present(opt_arg)) then
        arg = opt_arg
      else
        arg = default_value
      endif
    end function
    pure function get_arg_real64(default_value, opt_arg) result(arg)
      real(REAL64) :: arg
      real(REAL64), intent(in) :: default_value
      real(REAL64), intent(in), optional :: opt_arg
      if(present(opt_arg)) then
        arg = opt_arg
      else
        arg = default_value
      endif
    end function
    pure function get_arg_char(default_value, opt_arg) result(arg)
      character(len=default_str_len) :: arg
      character(len=*), intent(in) :: default_value
      character(len=*), intent(in), optional :: opt_arg
      if(present(opt_arg)) then
        arg = trim(opt_arg)
      else
        arg = trim(default_value)
      endif
    end function


    ! https://gist.github.com/t-nissie/479f0f16966925fa29ea
    recursive subroutine quicksort(a, first, last)
      integer(iintegers), intent(inout) :: a(:)
      integer(iintegers), intent(in) :: first, last
      integer(iintegers) :: i, j, x, t

      x = a( (first+last) / 2 )
      i = first
      j = last
      do
        do while (a(i) < x)
          i=i+1
        end do
        do while (x < a(j))
          j=j-1
        end do
        if (i >= j) exit
        t = a(i);  a(i) = a(j);  a(j) = t
        i=i+1
        j=j-1
      end do
      if (first < i-1) call quicksort(a, first, i-1)
      if (j+1 < last)  call quicksort(a, j+1, last)
    end subroutine quicksort

    ! https://stackoverflow.com/questions/44198212/a-fortran-equivalent-to-unique
    function unique(inp)
      !! usage sortedlist = unique(list)
      !! or reshape it first to 1D: sortedlist = unique(reshape(list, [size(list)]))
      integer(iintegers), intent(in) :: inp(:)
      integer(iintegers) :: list(size(inp))
      integer(iintegers), allocatable :: unique(:)
      integer(iintegers) :: n
      logical :: mask(size(inp))

      list = inp
      n=size(list)
      call quicksort(list, i1, n)

      ! cull duplicate indices
      mask = .False.
      mask(1:n-1) = list(1:n-1) == list(2:n)
      allocate(unique(count(.not.mask)))
      unique = pack(list, .not.mask)
    end function unique

    ! @brief: map from the flattened numbering to the coefficients in Ndims
    ! This is something like numpy.unravel
    ! offset could usually look like [1, size(arr, dim=1), size(arr, dim=1)*size(arr, dim=2), ...]
    pure subroutine ind_1d_to_nd(offsets, ind, nd_indices)
      integer(iintegers), intent(in) :: offsets(:)
      integer(iintegers), intent(in) :: ind
      integer(iintegers), intent(out) :: nd_indices(size(offsets))
      integer(iintegers) :: k

      k = ubound(nd_indices,1) ! last dimension
      nd_indices(k) = (ind-1) / offsets(k) +1

      do k=ubound(offsets,1)-1, lbound(offsets,1), -1
        nd_indices(k) = modulo(ind-1, offsets(k+1)) / offsets(k) +1
      enddo
    end subroutine

    ! @brief: map indices in N-dimensions to a flattened array
    ! This is something like numpy.ravel
    ! offset could usually look like [1, size(arr, dim=1), size(arr, dim=1)*size(arr, dim=2), ...]
    pure function ind_nd_to_1d(offsets, nd_indices) result (i1d)
      integer(iintegers), intent(in) :: offsets(:)
      integer(iintegers), intent(in) :: nd_indices(:)
      integer(iintegers) :: i1d
      i1d = dot_product(nd_indices(:)-1, offsets) +1
    end function

    pure subroutine ndarray_offsets(arrshape, offsets)
      integer(iintegers),intent(in) :: arrshape(:)
      integer(iintegers),intent(out) :: offsets(size(arrshape))
      offsets(1) = 1
      offsets(2:size(arrshape)) = arrshape(1:size(arrshape)-1)
      offsets = cumprod(offsets)
    end subroutine

    function get_mem_footprint(comm)
#include "petsc/finclude/petscsys.h"
      use petsc
      integer(mpiint),intent(in) :: comm
      real(ireals) :: get_mem_footprint
      PetscLogDouble :: memory_footprint
      integer(mpiint) :: ierr
      get_mem_footprint = zero

      call mpi_barrier(comm, ierr)
      call PetscMemoryGetCurrentUsage(memory_footprint, ierr); call CHKERR(ierr)

      get_mem_footprint = real(memory_footprint / 1024. / 1024. / 1024., ireals)

      !  if(ldebug) print *,myid,'Memory Footprint',memory_footprint, 'B', get_mem_footprint, 'G'
    end function

    function reverse_1d_real32(inp) result(rev)
      real(real32),intent(in) :: inp(:)
      real(real32) :: rev(size(inp,1))
      rev = inp(ubound(inp,1):lbound(inp,1):-1)
    end function
    function reverse_1d_real64(inp) result(rev)
      real(real64),intent(in) :: inp(:)
      real(real64) :: rev(size(inp,1))
      rev = inp(ubound(inp,1):lbound(inp,1):-1)
    end function
    function reverse_2d_real32(inp, dim) result(rev)
      real(real32),intent(in) :: inp(:,:)
      integer(iintegers), optional, intent(in) :: dim
      real(real32) :: rev(size(inp,1),size(inp,2))
      integer(iintegers) :: rdim
      rdim = get_arg(i1, dim)
      select case(rdim)
      case(1)
        rev = inp(ubound(inp,1):lbound(inp,1):-1, :)
      case(2)
        rev = inp(:, ubound(inp,2):lbound(inp,2):-1)
      case default
        call CHKERR(1_mpiint, 'dimension of reverse array does not fit input array')
      end select
    end function
    function reverse_2d_real64(inp, dim) result(rev)
      real(real64),intent(in) :: inp(:,:)
      integer(iintegers), optional, intent(in) :: dim
      real(real64) :: rev(size(inp,1),size(inp,2))
      integer(iintegers) :: rdim
      rdim = get_arg(i1, dim)
      select case(rdim)
      case(1)
        rev = inp(ubound(inp,1):lbound(inp,1):-1, :)
      case(2)
        rev = inp(:, ubound(inp,2):lbound(inp,2):-1)
      case default
        call CHKERR(1_mpiint, 'dimension of reverse array does not fit input array')
      end select
    end function
    function reverse_3d_real32(inp, dim) result(rev)
      real(real32),intent(in) :: inp(:,:,:)
      integer(iintegers), optional, intent(in) :: dim
      real(real32) :: rev(size(inp,1), size(inp,2), size(inp,3))
      integer(iintegers) :: rdim
      rdim = get_arg(i1, dim)
      select case(rdim)
      case(1)
        rev = inp(ubound(inp,rdim):lbound(inp,rdim):-1, :, :)
      case(2)
        rev = inp(:, ubound(inp,rdim):lbound(inp,rdim):-1, :)
      case(3)
        rev = inp(:, :, ubound(inp,rdim):lbound(inp,rdim):-1)
      case default
        call CHKERR(1_mpiint, 'dimension of reverse array does not fit input array')
      end select
    end function
    function reverse_3d_real64(inp, dim) result(rev)
      real(real64),intent(in) :: inp(:,:,:)
      integer(iintegers), optional, intent(in) :: dim
      real(real64) :: rev(size(inp,1), size(inp,2), size(inp,3))
      integer(iintegers) :: rdim
      rdim = get_arg(i1, dim)
      select case(rdim)
      case(1)
        rev = inp(ubound(inp,rdim):lbound(inp,rdim):-1, :, :)
      case(2)
        rev = inp(:, ubound(inp,rdim):lbound(inp,rdim):-1, :)
      case(3)
        rev = inp(:, :, ubound(inp,rdim):lbound(inp,rdim):-1)
      case default
        call CHKERR(1_mpiint, 'dimension of reverse array does not fit input array')
      end select
    end function
    function reverse_4d_real32(inp, dim) result(rev)
      real(real32),intent(in) :: inp(:,:,:,:)
      integer(iintegers), optional, intent(in) :: dim
      real(real32) :: rev(size(inp,1), size(inp,2), size(inp,3), size(inp,4))
      integer(iintegers) :: rdim
      rdim = get_arg(i1, dim)
      select case(rdim)
      case(1)
        rev = inp(ubound(inp,rdim):lbound(inp,rdim):-1, :, :, :)
      case(2)
        rev = inp(:, ubound(inp,rdim):lbound(inp,rdim):-1, :, :)
      case(3)
        rev = inp(:, :, ubound(inp,rdim):lbound(inp,rdim):-1, :)
      case(4)
        rev = inp(:, :, :, ubound(inp,rdim):lbound(inp,rdim):-1)
      case default
        call CHKERR(1_mpiint, 'dimension of reverse array does not fit input array')
      end select
    end function
    function reverse_4d_real64(inp, dim) result(rev)
      real(real64),intent(in) :: inp(:,:,:,:)
      integer(iintegers), optional, intent(in) :: dim
      real(real64) :: rev(size(inp,1), size(inp,2), size(inp,3), size(inp,4))
      integer(iintegers) :: rdim
      rdim = get_arg(i1, dim)
      select case(rdim)
      case(1)
        rev = inp(ubound(inp,rdim):lbound(inp,rdim):-1, :, :, :)
      case(2)
        rev = inp(:, ubound(inp,rdim):lbound(inp,rdim):-1, :, :)
      case(3)
        rev = inp(:, :, ubound(inp,rdim):lbound(inp,rdim):-1, :)
      case(4)
        rev = inp(:, :, :, ubound(inp,rdim):lbound(inp,rdim):-1)
      case default
        call CHKERR(1_mpiint, 'dimension of reverse array does not fit input array')
      end select
    end function

    function cstr(inp, color)
      character(len=*), intent(in) :: inp, color
      character(len=len(inp)+9) :: cstr
      cstr = achar(27)
      select case(color)
      case('dark grey')
        cstr = achar(27)//'[90m'
      case('black')
        cstr = achar(27)//'[30m'
      case('peach')
        cstr = achar(27)//'[91m'
      case('red')
        cstr = achar(27)//'[31m'
      case('light green')
        cstr = achar(27)//'[92m'
      case('green')
        cstr = achar(27)//'[32m'
      case('light yellow')
        cstr = achar(27)//'[93m'
      case('yellow')
        cstr = achar(27)//'[33m'
      case('light blue')
        cstr = achar(27)//'[94m'
      case('blue')
        cstr = achar(27)//'[34m'
      case('pink')
        cstr = achar(27)//'[95m'
      case('purple')
        cstr = achar(27)//'[35m'
      case('light aqua')
        cstr = achar(27)//'[96m'
      case('aqua')
        cstr = achar(27)//'[36m'
      case('pearl white')
        cstr = achar(27)//'[97m'

      case default
        call CHKERR(1_mpiint, 'dont know the color code for '//color)
      end select

      cstr = trim(cstr)//trim(inp)//achar(27)//'[0m'
    end function

    function char_arr_to_str(inp, deliminator) result(out_str)
      character(len=*), intent(in) :: inp(:)
      character(len=*), intent(in), optional :: deliminator
      character(:), allocatable :: out_str
      character(len=2),parameter :: default_delim=', '
      integer :: i

      if(size(inp).eq.0) then
        out_str=''
        return
      endif

      if(present(deliminator)) then
      out_str = trim(inp(1))
      do i = 2, size(inp)
        out_str = trim(out_str)//deliminator//trim(inp(i))
      enddo
    else
      out_str = trim(inp(1))
      do i = 2, size(inp)
        out_str = trim(out_str)//default_delim//trim(inp(i))
      enddo
    endif
    end function


! solve_quadratic equation ax2 + 2bx + c = 0
pure subroutine solve_quadratic_r32(a, b, c, x, ierr)
  real(kind=REAL32),intent(in) :: a,b,c
  real(kind=REAL32),dimension(2), intent(out) :: x
  integer(mpiint), intent(out) :: ierr

  real(kind=REAL32) :: q ,dis
  ierr = 0

  dis = b**2 - 4*a*c
  if (dis.lt.0) then
    ierr = 1
    return
  endif

  if (b.lt.0) then
    q = -.5_REAL32*(b - sqrt(dis))
  else
    q = -.5_REAL32*(b + sqrt(dis))
  endif
  x(1) = q/a
  if(abs(q).lt.epsilon(q)) then
    x(2) = x(1)
  else
    x(2) = c/q
  endif
  if(x(1).gt.x(2)) x = [x(2), x(1)]
end subroutine

pure subroutine solve_quadratic_r64(a, b, c, x, ierr)
  real(kind=REAL64),intent(in) :: a,b,c
  real(kind=REAL64),dimension(2), intent(out) :: x
  integer(mpiint), intent(out) :: ierr

  real(kind=REAL64) :: q ,dis
  ierr = 0

  dis = b**2 - 4*a*c
  if (dis.lt.0) then
    ierr = 1
    return
  endif

  if (b.lt.0) then
    q = -.5_REAL64*(b - sqrt(dis))
  else
    q = -.5_REAL64*(b + sqrt(dis))
  endif
  x(:) = [ q/a, c/q ]
  if(x(1).gt.x(2)) x = [x(2), x(1)]
end subroutine

! helper to sample a linspace
pure function linspace_r64(idx, rng, N) result(sample_pnt)
  integer(iintegers),intent(in) :: idx, N
  real(kind=REAL64),dimension(2), intent(in) :: rng
  real(kind=kind(rng)) :: sample_pnt
  if(N.gt.i1) then
    sample_pnt = rng(1) + (real(idx, kind(rng))-1) * ( rng(2)-rng(1) ) &
      / real(N-1, kind=kind(sample_pnt))
  else
    sample_pnt = rng(1)
  endif
end function
pure function linspace_r32(idx, rng, N) result(sample_pnt)
  integer(iintegers),intent(in) :: idx, N
  real(kind=REAL32),dimension(2), intent(in) :: rng
  real(kind=kind(rng)) :: sample_pnt
  if(N.gt.i1) then
    sample_pnt = rng(1) + (real(idx, kind(rng))-1) * ( rng(2)-rng(1) ) &
      / real(N-1, kind=kind(sample_pnt))
  else
    sample_pnt = rng(1)
  endif
end function


! determine if array is (strictly) monotoneous increasing/decreasing
pure function assert_arr_is_monotonous_r32(arr, lincreasing, lstrict) result(lis_linear)
  real(REAL32), intent(in) :: arr(:)
  logical, intent(in) :: lincreasing, lstrict
  logical :: lis_linear
  integer(iintegers) :: k
  if(lincreasing) then
    if(lstrict) then
      do k=2,size(arr)
        if(arr(k).le.arr(k-1)) then
          lis_linear = .False.
          return
        endif
      enddo
    else
      do k=2,size(arr)
        if(arr(k).lt.arr(k-1)) then
          lis_linear = .False.
          return
        endif
      enddo
    endif
  else
    if(lstrict) then
      do k=2,size(arr)
        if(arr(k).ge.arr(k-1)) then
          lis_linear = .False.
          return
        endif
      enddo
    else
      do k=2,size(arr)
        if(arr(k).gt.arr(k-1)) then
          lis_linear = .False.
          return
        endif
      enddo
    endif
  endif
  lis_linear = .True.
end function
pure function assert_arr_is_monotonous_r64(arr, lincreasing, lstrict) result(lis_linear)
  real(REAL64), intent(in) :: arr(:)
  logical, intent(in) :: lincreasing, lstrict
  logical :: lis_linear
  integer(iintegers) :: k
  if(lincreasing) then
    if(lstrict) then
      do k=2,size(arr)
        if(arr(k).le.arr(k-1)) then
          lis_linear = .False.
          return
        endif
      enddo
    else
      do k=2,size(arr)
        if(arr(k).lt.arr(k-1)) then
          lis_linear = .False.
          return
        endif
      enddo
    endif
  else
    if(lstrict) then
      do k=2,size(arr)
        if(arr(k).ge.arr(k-1)) then
          lis_linear = .False.
          return
        endif
      enddo
    else
      do k=2,size(arr)
        if(arr(k).gt.arr(k-1)) then
          lis_linear = .False.
          return
        endif
      enddo
    endif
  endif
  lis_linear = .True.
end function
  end module
