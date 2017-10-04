
#ifdef STRATOKILLER
subroutine damping (ktop_crm,debugflag)
#else
subroutine damping
#endif

!  "Spange"-layer damping at the domain top region

use vars
use microphysics, only: micro_field, index_water_vapor
implicit none

#ifdef STRATOKILLER
integer, intent(in) :: ktop_crm,debugflag ! CRM grid level index for tropopause
#endif
real tau_min	! minimum damping time-scale (at the top)
real tau_max    ! maxim damping time-scale (base of damping layer)
real damp_depth ! damping depth as a fraction of the domain height
parameter(tau_min=60., tau_max=450.)
#ifndef STRATOKILLER
parameter(damp_depth=0.4)
#endif

real tau(nzm), t0new(nzm), u0new(nzm), v0new(nzm)  !hparish: t0new is local to this subroutine. added to not interfere with t0 inside diagnose which is used for crm_acc. 
integer i, j, k, n_damp

#ifdef STRATOKILLER
  damp_depth = 1. - z(ktop_crm+2)/z(nzm)
#endif
if(tau_min.lt.2*dt) then
   print*,'Error: in damping() tau_min is too small!'
   call task_abort()
end if

do k=nzm,1,-1
 if(z(nzm)-z(k).lt.damp_depth*z(nzm)) then 
   n_damp=nzm-k+1
 endif
end do

do k=nzm,nzm-n_damp,-1
 tau(k) = tau_min *(tau_max/tau_min)**((z(nzm)-z(k))/(z(nzm)-z(nzm-n_damp)))
 tau(k)=1./tau(k)
end do

#ifdef STRATOKILLER
if (debugflag .eq. 1) then
  write (6,*) 'HEY STRATOKILLER prior to hacking tau profile:'
  do k=1,nzm
    write (6,*) 'k=',k,', tau(k)=',tau(k)
  end do
endif

do k=1,nzm
  if (k .ge. ktop_crm+2) then
    tau(k) = 1. / tau_min ! Complete damping of velocity, temperature fluctuations 2 layers above the tropopause.
  endif
end do

if (debugflag .eq. 1) then
  write (6,*) 'HEY STRATOKILLER after hacking the profile:'
  do k=1,nzm
    write (6,*) 'k=',k,', tau(k)=',tau(k)
  end do
endif
#endif

!+++mhwang recalculate grid-mean u0, v0, t0 first, 
! as t have been updated. No need for qv0, as
! qv has not been updated yet the calculation of qv0. 
do k=1, nzm
! u0(k)=0.0
! v0(k)=0.0
! t0(k)=0.0
 u0new(k)=0.0
 v0new(k)=0.0
 t0new(k)=0.0   !hparish modified t0 to t0new because we want the t0 from diagnose routine to be untouched for crm_acc. same for u0 and v0.
 do j=1, ny
  do i=1, nx
!    u0(k) = u0(k) + u(i,j,k)/(nx*ny)
!    v0(k) = v0(k) + v(i,j,k)/(nx*ny)
!    t0(k) = t0(k) + t(i,j,k)/(nx*ny)
    u0new(k) = u0new(k) + u(i,j,k)/(nx*ny)
    v0new(k) = v0new(k) + v(i,j,k)/(nx*ny)
    t0new(k) = t0new(k) + t(i,j,k)/(nx*ny)  !hparish modified to accumulate local t0new rather than t0.
  end do
 end do
end do
!---mhwang

do k = nzm, nzm-n_damp, -1
   do j=1,ny
    do i=1,nx
      dudt(i,j,k,na)= dudt(i,j,k,na)-(u(i,j,k)-u0new(k)) * tau(k)
      dvdt(i,j,k,na)= dvdt(i,j,k,na)-(v(i,j,k)-v0new(k)) * tau(k)
      dwdt(i,j,k,na)= dwdt(i,j,k,na)-w(i,j,k) * tau(k)
      t(i,j,k)= t(i,j,k)-dtn*(t(i,j,k)-t0new(k)) * tau(k)
! In the old version (SAM7.5?) of SAM, water vapor is the prognostic variable for the two-moment microphyscs. 
! So the following damping approach can lead to the negative water vapor. 
!      micro_field(i,j,k,index_water_vapor)= micro_field(i,j,k,index_water_vapor)- &
!                                    dtn*(qv(i,j,k)+qcl(i,j,k)+qci(i,j,k)-q0(k)) * tau(k)
! a simple fix (Minghuai Wang, 2011-08):
      micro_field(i,j,k,index_water_vapor)= micro_field(i,j,k,index_water_vapor)- &
                                    dtn*(qv(i,j,k)-qv0(k)) * tau(k)
    end do! i 
   end do! j
end do ! k

end subroutine damping
