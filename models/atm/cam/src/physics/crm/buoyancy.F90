
subroutine buoyancy()

use vars
use params
implicit none
	
integer i,j,k,kb
real du(nx,ny,nz,3)

if(docolumn) return

if(dostatis) then 

  do k=1,nzm
    do j=1,ny
      do i=1,nx
         du(i,j,k,3)=dwdt(i,j,k,na)
      end do
    end do
  end do

endif

do k=2,nzm	
 kb=k-1
 do j=1,ny
  do i=1,nx

   dwdt(i,j,k,na)=dwdt(i,j,k,na) + 0.5*( &  !hparish confirmed with Marat that the 0.5 factor should not be removed for this particular way of bouyancy calculation.
      bet(k)* &
     ( tabs0(k)*(epsv*(qv(i,j,k)-qv0(k))-(qcl(i,j,k)+qci(i,j,k)-qn0(k)+qpl(i,j,k)+qpi(i,j,k)-qp0(k))) &
       +(tabs(i,j,k)-tabs0(k))*(1.+epsv*qv0(k)-qn0(k)-qp0(k)) ) &
    + bet(kb)* &
     ( tabs0(kb)*(epsv*(qv(i,j,kb)-qv0(kb))-(qcl(i,j,kb)+qci(i,j,kb)-qn0(kb)+qpl(i,j,kb)+qpi(i,j,kb)-qp0(kb))) &
       +(tabs(i,j,kb)-tabs0(kb))*(1.+epsv*qv0(kb)-qn0(kb)-qp0(kb)) ) ) 

  end do ! i
 end do ! j
end do ! k

if(dostatis) then                  !to calculate the buoyancy profile.
  do k=1,nzm
    do j=1,ny
      do i=1,nx
        du(i,j,k,1)=0.
        du(i,j,k,2)=0.
        du(i,j,k,3)=dwdt(i,j,k,na)-du(i,j,k,3)
      end do
    end do
  end do

  call stat_tke(du,tkelebuoy)

endif

end subroutine buoyancy


