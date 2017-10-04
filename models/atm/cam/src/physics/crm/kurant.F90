#ifdef BLOSSKURANT

subroutine kurant

use vars

implicit none

integer i, j, k, ncycle1(1),ncycle2(1)
real wm(nz)  ! maximum vertical wind velocity
real um(nz) ! maximum zonal wind velocity
real vm(nz) ! maximum meridional wind velocity
real tkhmax(nz)
real cfl, cfl_adv, cfl_sgs, cflsq

integer kmax

!bloss: CFL limits for third-order adams-bashforth with second-order advection and diffusion
real, parameter :: cfl_adv_max = 0.72, cfl_sgs_max = 0.5

!bloss: add a buffer to keep cfl away from the limiting value
real, parameter :: cfl_safety_factor = 1.3

ncycle = 1
	
wm(nz)=0.
do k = 1,nzm
 tkhmax(k) = maxval(tkh(1:nx,1:ny,k))
 wm(k) = maxval(abs(w(1:nx,1:ny,k)))
 um(k) = maxval(abs(u(1:nx,1:ny,k)))
 vm(k) = maxval(abs(v(1:nx,1:ny,k)))
end do
w_max=max(w_max,maxval(w(1:nx,1:ny,1:nz)))

!bloss: Revision of cfl computation based on earlier versions in UW versions of SAM
!  by myself and Peter Caldwell.
cflsq = 0.
kmax = -1
do k=1,nzm
   ! if advection is not dimension split, cfl should be sum across dimensions, rather than max.
   cfl_adv = um(k)*dt/dx & ! cfl in x
        + YES3D*vm(k)*dt/dy & ! cfl in y
        + MAX( wm(k)/adzw(k), wm(k+1)/adzw(k+1) ) *dt/dz ! cfl in z

   ! diffusion has an analogous criterion, with a cfl-like quantity = tkh*dt/dx^2
   cfl_sgs = tkhmax(k)*grdf_x(k)*dt/dx**2 & ! limit in x
        + YES3D*tkhmax(k)*grdf_y(k)*dt/dy**2 & ! limit in y
        + tkhmax(k)*grdf_z(k)*dt/(dz*adz(k))**2 ! limit in z

   ! combine these two assuming stability region is elliptical
   if((cfl_adv/cfl_adv_max)**2 + (cfl_sgs/cfl_sgs_max)**2.GT.cflsq) then
     kmax = k
     cflsq = (cfl_adv/cfl_adv_max)**2 + (cfl_sgs/cfl_sgs_max)**2
   end if
end do

cfl = SQRT(cflsq)
	
ncycle = max(1,ceiling(cfl*cfl_safety_factor))

if(dompi) then
  ncycle1(1)=ncycle
  call task_max_integer(ncycle1,ncycle2,1)
  ncycle=ncycle2(1)
end if
if(ncycle.gt.4) then
   if(masterproc) then
     print *,'the number of cycles exceeded 4.'
     write(*,921) latitude(1,1), longitude(1,1), kmax
921  format('The cfl violation occurred at lat,lon = ',2f10.4,' and level k=',I4)
     write(*,*) ' ------------- '
     write(*,*) 'Values of umax, vmax, wmax and tkhmax by level'
     do k = 1,nzm
       write(*,922) k, um(k), vm(k), wm(k), tkhmax(k)
     end do
922  format('k = ',i4, ' umax/vmax/wmax(k) = ',3e12.4,' tkhmax(k) = ',e12.4)
     write(*,*) ' ------------- '
     write(*,*) 'Stopping now ...'
   end if
   call task_abort()
end if

end subroutine kurant	



#else
subroutine kurant

use vars

implicit none

integer i, j, k, ncycle1(1),ncycle2(1)
real wm(nz)  ! maximum vertical wind velocity
real uhm(nz) ! maximum horizontal wind velocity
real tkhmax(nz)
real cfl

ncycle = 1
	
wm(nz)=0.
do k = 1,nzm
 tkhmax(k) = maxval(tkh(1:nx,1:ny,k))
 wm(k) = maxval(abs(w(1:nx,1:ny,k)))
 uhm(k) = sqrt(maxval(u(1:nx,1:ny,k)**2+YES3D*v(1:nx,1:ny,k)**2))
end do
w_max=max(w_max,maxval(w(1:nx,1:ny,1:nz)))

cfl = 0.
do k=1,nzm
  cfl = max(cfl,uhm(k)*dt*sqrt((1./dx)**2+YES3D*(1./dy)**2), &
                   max(wm(k),wm(k+1))*dt/(dz*adzw(k)) )
  cfl = max(cfl,	&
     0.5*tkhmax(k)*grdf_z(k)*dt/(dz*adzw(k))**2, &
     0.5*tkhmax(k)*grdf_x(k)*dt/dx**2, &
     YES3D*0.5*tkhmax(k)*grdf_y(k)*dt/dy**2)
end do
	
  ncycle = max(1,ceiling(cfl/0.7))


if(dompi) then
  ncycle1(1)=ncycle
  call task_max_integer(ncycle1,ncycle2,1)
  ncycle=ncycle2(1)
end if
#ifdef LESVISCOSITY
if(ncycle.gt.8) then
   if(masterproc) print *,'# cycles exceeded 8. ncycle = ', ncycle
#else
if(ncycle.gt.4) then
   if(masterproc) print *,'# cycles exceeded 4. ncycle = ', ncycle
#endif
   if(masterproc) print *,'----uhm,wm = ', uhm,wm
   if(masterproc) print *,'----tkhmax = ', tkhmax
   call task_abort()
end if

end subroutine kurant	
#endif
