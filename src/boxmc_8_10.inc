
subroutine update_dir_stream_8_10(bmc,p,S,N)
        class(t_boxmc_8_10) :: bmc
        type(photon),intent(in) :: p
        real(ireals),intent(inout) :: S(:)
        integer(iintegers),intent(inout) :: N(:)

!            1       2
!               3       4
!         _______________
!        |               |
!      6 |           8   | 
!        |               |
!        |               |
!        |    7          |
!      5 |_______________| 
    select case (p%side)
    case(1:2)
      if(p%loc(1).le.p%dx/2.and.p%loc(2).le.p%dy/2) then
        S(1) = S(1)+p%weight
        N(1) = N(1)+i1
        return
      else if(p%loc(1).gt.p%dx/2.and.p%loc(2).le.p%dy/2) then
        S(2) = S(2)+p%weight
        N(2) = N(2)+i1
        return
      else if(p%loc(1).le.p%dx/2.and.p%loc(2).gt.p%dy/2) then
        S(3) = S(3)+p%weight
        N(3) = N(3)+i1
        return
      else if(p%loc(1).gt.p%dx/2.and.p%loc(2).gt.p%dy/2) then
        S(4) = S(4)+p%weight
        N(4) = N(4)+i1
        return
      else
        print *,'Couldnt find a stream on to which I can put the photon weight on?!'
        call print_photon(p)
      endif

    case(3:4)

      if(p%loc(3).le.p%dz/2 ) then
        S(5) = S(5)+p%weight
        N(5) = N(5)+i1
        return
      else if(p%loc(3).gt.p%dz/2 ) then
        S(6) = S(6)+p%weight
        N(6) = N(6)+i1
        return
      else
        print *,'Couldnt find a stream on to which I can put the photon weight on?!'
        call print_photon(p)
      endif
    case(5:6)

      if(p%loc(3).le.p%dz/2 ) then
        S(7) = S(7)+p%weight
        N(7) = N(7)+i1
        return
      else if(p%loc(3).gt.p%dz/2 ) then
        S(8) = S(8)+p%weight
        N(8) = N(8)+i1
        return
      else
        print *,'Couldnt find a stream on to which I can put the photon weight on?!'
        call print_photon(p)
      endif
    case default
      print *,'Dont know what to do with this p%side'
      call print_photon(p)
    end select
end subroutine
subroutine update_diff_stream_8_10(bmc,p,S,N)
        class(t_boxmc_8_10) :: bmc
        type(photon),intent(in) :: p
        real(ireals),intent(inout) :: S(:)
        integer(iintegers),intent(inout) :: N(:)

!         _______1_______
!        |           10  |
!      5 |            8  | 6
!        |               |
!        |   9           |
!        |   7           |
!      3 |_______________| 4
!                2

        if(p%side.eq.1) then
                S(1) = S(1)+p%weight
                N(1) = N(1)+i1
                return
        else if(p%side.eq.2) then
                S(2) = S(2)+p%weight
                N(2) = N(2)+i1
                return

        else if(p%side.eq.3 .and. p%dir(3).le.zero ) then
                S(3) = S(3)+p%weight
                N(3) = N(3)+i1
                return
        else if(p%side.eq.3 .and. p%dir(3).gt.zero ) then
                S(5) = S(5)+p%weight
                N(5) = N(5)+i1
                return

        else if(p%side.eq.4 .and. p%dir(3).le.zero ) then
                S(4) = S(4)+p%weight
                N(4) = N(4)+i1
                return
        else if(p%side.eq.4 .and. p%dir(3).gt.zero ) then
                S(6) = S(6)+p%weight
                N(6) = N(6)+i1
                return

        else if(p%side.eq.5 .and. p%dir(3).le.zero ) then
                S(7) = S(7)+p%weight
                N(7) = N(7)+i1
                return
        else if(p%side.eq.6 .and. p%dir(3).le.zero ) then
                S(8) = S(8)+p%weight
                N(8) = N(8)+i1
                return
        else if(p%side.eq.5 .and. p%dir(3).gt.zero ) then
                S(9) = S(9)+p%weight
                N(9) = N(9)+i1
                return
        else if(p%side.eq.6 .and. p%dir(3).gt.zero ) then
                S(10) =S(10)+p%weight
                N(10) =N(10)+i1
                return
        else
                print *,'Couldnt find a stream on to which I can put the photon weight on?!'
                call print_photon(p)
                call exit
        endif
end subroutine

subroutine init_dir_photon_8_10(bmc,p,src,direct,initial_dir,dx,dy,dz)
        class(t_boxmc_8_10) :: bmc
        type(photon),intent(inout) :: p
        double precision,intent(in) :: dx,dy,dz,initial_dir(3)
        integer(iintegers),intent(in) :: src
        logical,intent(in) :: direct

        p%alive = .False.

        if(src.eq.1) then
                p%loc = (/L(dx)/2     , L(dy)/2     ,    dz  /)
        else if(src.eq.2) then
                p%loc = (/dx/2+L(dx)/2, L(dy)/2     ,    dz  /)
        else if(src.eq.3) then
                p%loc = (/L(dx)/2     , dy/2+L(dy)/2,    dz  /)
        else if(src.eq.4) then
                p%loc = (/dx/2+L(dx)/2, dy/2+L(dy)/2,    dz  /)
        else if(src.eq.5) then
                p%loc = (/  zero      , L(dy)       , L(dz)/2/)
        else if(src.eq.6) then
                p%loc = (/  zero      , L(dy)       , dz/2+L(dz)/2/)
        else if(src.eq.7) then
                p%loc = (/L(dx)       ,   zero      , L(dz)/2/)
        else if(src.eq.8) then
                p%loc = (/L(dx)       ,   zero      , dz/2+L(dz)/2/)
        else
                print *,'Dont know what to do with source spec:',src
                call exit
        endif

        p%weight=one
        p%dx   = dx
        p%dy   = dy
        p%dz   = dz
        p%alive = .True.
        p%direct= direct
        p%side = int(nil)
        p%src  = src
        p%dir = initial_dir
end subroutine

subroutine init_diff_photon_8_10(bmc,p,src,dx,dy,dz)
        class(t_boxmc_8_10) :: bmc
        type(photon),intent(inout) :: p
        double precision,intent(in) :: dx,dy,dz
        integer(iintegers),intent(in) :: src
        double precision,parameter :: I=1.,O=0.

        if(src.eq.1) then
                p%loc = (/L(dx), L(dy),    dz  /)
                p%dir = (/s()   , s()   ,   -I  /)
        else if(src.eq.2) then
                p%loc = (/L(dx), L(dy),    O /)
                p%dir = (/s()   , s()   ,    I /)
        else if(src.eq.3) then
                p%loc = (/  O   , L(dy), L(dz)/)
                p%dir = (/  I   , s()   , -R()   /)
        else if(src.eq.4) then
                p%loc = (/ dx   , L(dy), L(dz)/)
                p%dir = (/ -I   , s()   , -R()   /)
        else if(src.eq.5) then
                p%loc = (/  O   , L(dy), L(dz)/)
                p%dir = (/  I   , s()   ,R()   /)
        else if(src.eq.6) then
                p%loc = (/ dx   , L(dy), L(dz)/)
                p%dir = (/ -I   , s()   ,R()   /)
        else if(src.eq.7) then
                p%loc = (/L(dx),   O   , L(dz)/)
                p%dir = (/s()  ,   I   , -R()   /)
        else if(src.eq.8) then
                p%loc = (/L(dx),  dy   , L(dz)/)
                p%dir = (/s()  , -I    , -R()   /)
        else if(src.eq.9) then
                p%loc = (/L(dx),   O   , L(dz)/)
                p%dir = (/s()  ,   I   ,R()   /)
        else if(src.eq.10) then
                p%loc = (/L(dx),  dy   , L(dz)/)
                p%dir = (/s()  , -I    ,R()   /)
        else
                print *,'Dont know what to do with source spec:',src
                call exit
        endif

        p%weight=one
        p%dx   = dx
        p%dy   = dy
        p%dz   = dz
        p%alive = .True.
        p%direct= .False.
        p%side = int(nil)
        p%src  = src
        p%dir = p%dir/norm(p%dir)

end subroutine

subroutine intersect_distance_8_10(bmc,p,max_dist)
        class(t_boxmc_8_10) :: bmc
        type(photon),intent(inout) :: p
        double precision,intent(out) :: max_dist

        double precision :: x,y,z
        integer(iintegers) :: i,sides(3)

        double precision :: dist(3)

        !crossing with bottom and top plane:
          if(p%dir(3).ge.zero) then
            max_dist = hit_plane(p,[zero,zero,p%dz ],[zero,zero,one])
            p%side=1 
            x = p%loc(1)+p%dir(1)*max_dist
            y = p%loc(2)+p%dir(2)*max_dist
            if( ( x.ge.zero .and. x.le.p%dx) .and. ( y.ge.zero .and. y.le.p%dy) ) return
            dist(1) = max_dist; sides(1) = 1
          endif
          if(p%dir(3).le.zero) then
            max_dist = hit_plane(p,[zero,zero,zero ],[zero,zero,one])
            p%side=2
            x = p%loc(1)+p%dir(1)*max_dist
            y = p%loc(2)+p%dir(2)*max_dist
            if( ( x.ge.zero .and. x.le.p%dx) .and. ( y.ge.zero .and. y.le.p%dy) ) return
            dist(1) = max_dist; sides(1) = 2
          endif

          !crossing with left and right plane:
          if(p%dir(1).le.zero) then
            max_dist = hit_plane(p,[ zero ,zero,zero],[one,zero,zero])
            p%side=3
            y = p%loc(2)+p%dir(2)*max_dist
            z = p%loc(3)+p%dir(3)*max_dist
            if( ( y.ge.zero .and. y.le.p%dy) .and. ( z.ge.zero .and. z.le.p%dz) ) return
            dist(2) = max_dist; sides(2) = 3
          endif
          if(p%dir(1).ge.zero) then
            max_dist = hit_plane(p,[ p%dx ,zero,zero],[one,zero,zero])
            p%side=4
            y = p%loc(2)+p%dir(2)*max_dist
            z = p%loc(3)+p%dir(3)*max_dist
            if( ( y.ge.zero .and. y.le.p%dy) .and. ( z.ge.zero .and. z.le.p%dz) ) return
            dist(2) = max_dist; sides(2) = 4
          endif

          !crossing with back and forward plane:
          if(p%dir(2).le.zero) then
            max_dist = hit_plane(p,[zero, zero ,zero],[zero,one,zero])
            p%side=5
            x = p%loc(1)+p%dir(1)*max_dist
            z = p%loc(3)+p%dir(3)*max_dist
            if( ( x.ge.zero .and. x.le.p%dx) .and. ( z.ge.zero .and. z.le.p%dz) ) return
            dist(3) = max_dist; sides(3) = 5
          endif
          if(p%dir(2).ge.zero) then
            max_dist = hit_plane(p,[zero, p%dy ,zero],[zero,one,zero])
            p%side=6
            x = p%loc(1)+p%dir(1)*max_dist
            z = p%loc(3)+p%dir(3)*max_dist
            if( ( x.ge.zero .and. x.le.p%dx) .and. ( z.ge.zero .and. z.le.p%dz) ) return
            dist(3) = max_dist; sides(3) = 6
          endif

          !Ohhh there was a problem.. maybe with numerics, seems that it may happen that we dont find a solution if norm of p%dir is not equal to one....
          max_dist=huge(dist)
          do i=1,3
            if(.not. approx(p%dir(i),zero) ) then
              if( dist(i).le.max_dist ) then
                p%side = sides(i)
                max_dist = dist(i)
              endif
            endif
          enddo

          print *,'should actually not be here at the end of crossings in intersect distance! - however, please check if distance makes sense?:',max_dist
          call print_photon(p)

end subroutine
  ! ******************* BOXMC 8 10 ************************
