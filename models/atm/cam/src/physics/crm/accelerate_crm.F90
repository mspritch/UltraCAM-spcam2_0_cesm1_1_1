#ifdef CRMACCEL
subroutine accelerate_crm (accel_factor,ceaseflag)

!----------------------------------------------------------
! author: Christopher Jones (cjones)
! email: crj6@uw.edu
! date: 5/21/2014
! ported to UPCAM: Mike Pritchard (pritch)
! date: 4/22/2015
!
! date: 8/29/2015, hparish: coefficients and internal variables are set to double precision.
! critical for UPCAM because of the emergence of loss of significant digits
! during subtraction when dtn is small.
! This is rooted in the very small changes in prognostics from t to t+dtn because
! dtn is O(1s) or smaller. If single precison is used, the symptom wil be lagging
! in Temp and Condensate fields and maybe others (not enough large scale tend) + brownian-like
! diffusion rendering the acceleration routine to practically add random noise to GCM
! which will not allow the PBL/MBL top inversion to form.
! The output fields will be distorted if single precision is used (for small dtn).
! Expect overhead when double precision. Therefore cost-wise acceleration makes sense only
! if the acc_factor is large. "How large?" needs to be tested and verified.
! For info: h.parish@uci.edu,  date: 8/29/2015.
!
! If do_accel = .true., accelerate the horizontal mean 
! tendency of t and qt=qcl+qci+qv by an additional factor 
! accel_factor.
!
! Specifically, if the horizontal mean tendency is "tend", 
! then the accelerated tendency for field phi will be 
! (dphi/dt) = tend + (accel_factor)*tend
!
! Note: Precipitation is NOT accelerated. The current version
!       also does not accelerate any tracers.
!----------------------------------------------------------
use shr_kind_mod, only: r8=>shr_kind_r8
use vars
use params
use microphysics, only: micro_field, index_water_vapor
implicit none

real(r8), intent (in) :: accel_factor
logical, intent (out):: ceaseflag
integer i,j,k
real(r8) :: coef
real(r8) :: dq_accel,tbaccel(nzm),qtbaccel(nzm)
real(r8) :: ttend_acc(nzm), qtend_acc(nzm), neg_qacc(nzm)
real(r8) :: taux
coef = 1./dble(nx*ny)

! NOTE: 
! neg_qacc(k) now equals horizontal mean 
! qt that was not removed from the system because acceleration
! tendency would have driven qt negative.

! calculate horizontal means
do k=1,nzm
  tbaccel(k)=0.    ! lse after physics (before applying accel)
  qtbaccel(k)=0.   ! qt after physics
  neg_qacc(k) = 0. ! excess qt that cannot be depleted
  do j=1,ny
    do i=1,nx
     tbaccel(k) = tbaccel(k)+t(i,j,k)
     qtbaccel(k) = qtbaccel(k) + qcl(i,j,k)+qci(i,j,k)+qv(i,j,k)
    end do
  end do
  tbaccel(k)=tbaccel(k)*coef
  qtbaccel(k)=qtbaccel(k)*coef
end do ! k

ceaseflag = .false.
do k=1,nzm
  do j=1,ny
      do i=1,nx
         if (abs(tbaccel(k)-t0(k)) .gt. 5.) then ! special clause for cases when dTdt is too large
            ceaseflag = .true.
! Note host crm_module receives this and adjusts number of integration steps accordingly 
            write (6,*) 'MDEBUG: |dT|>5K; dT,i,k=',tbaccel(k)-t0(k),i,k
         endif
      end do
  end do
end do

if (.not. ceaseflag) then
! apply acceleration tendency
do k=1,nzm
     ! pritch notes t0 and q0 are profiles of horizontal average field
        ! available in common.inc

           ! pritch asks  - what is dtn?
!              dtn = dt/ncycle (from crm.F)
!              dynamically adjusted timestep, modified based on
!              convergence issues

           ! pritch asks - what is t0 and when is it updated?
!               t0,q0 = mean domain profiles prior to CRM time
!               integration loop.

   ttend_acc(k) = accel_factor*(tbaccel(k)-t0(k))/dtn
   dq_accel = accel_factor*(qtbaccel(k) - q0(k))
   qtend_acc(k) = dq_accel/dtn
   do j=1,ny
      do i=1,nx
!         t(i,j,k)   = t(i,j,k)  +accel_factor*(tbaccel(k)-t0(k))
         t(i,j,k)   = max(50.,t(i,j,k) +accel_factor*(tbaccel(k)-t0(k))) ! pritch, avoid abs T going negative in cases of extreme horizontal mean temperature change
         micro_field(i,j,k,index_water_vapor) = &
              micro_field(i,j,k,index_water_vapor)+dq_accel

         ! enforce positivity and accumulate (negative) excess
         if(micro_field(i,j,k,index_water_vapor) .lt. 0.) then
            neg_qacc(k)=neg_qacc(k)+micro_field(i,j,k,index_water_vapor)
            micro_field(i,j,k,index_water_vapor)=0.
         end if

         ! add qt tendency to qv
         qv(i,j,k) = max(0.,qv(i,j,k)+dq_accel)   !hparish: the current calcultion of qv is not consistent with line 1185 of
!                                                 microphysics.f90. because dq_qccel represents the total water and not the water vapor.
!                                                 the possible reason is unknown. The introduction of parallel variables is questionble.
!                                                 like micro_field and qv, qcl, etc. which requires clean up. The variable doubling
!                                                 will also jeopardize the performance. date: 8/31/2015.
      end do
   end do
   neg_qacc(k) = neg_qacc(k)*coef
end do
endif
end subroutine accelerate_crm
#endif
