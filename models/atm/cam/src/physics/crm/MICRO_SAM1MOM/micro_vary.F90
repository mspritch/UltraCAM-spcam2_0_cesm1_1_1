#define MICRO_VARY
!#define MICDEBUG
#ifdef MICRO_VARY
module micro_vary
use micro_params ! will overwrite some of this module's values in ways intended
!to be felt elsewhere
use crm_grid, only: nzm
use time_manager, only: get_step_size
use mpishorthand, only : mpir8, mpiint, mpicom
use spmd_utils, only: masterproc,iam
use ppgrid, only: begchunk
use ifport

implicit none

real(r8) :: period_days_qci0 = 5.0
real(r8) :: phase_days_qci0 = 1.0

contains

subroutine init_micro_vary
! Set the random period and phase offset for each sinusoidal variation of
! microphysics...
  if (masterproc) then
    call random_seed()
    period_days_qci0 = rand()*5.0 + 5.0 ! 5-10 days, uniform random numer 
    phase_days_qci0 = rand()*period_days_qci0 ! randomly initiated phase.
#ifdef MICDEBUG
    write (6,*) 'YO masterproc chose period=',period_days_qci0,',phase=',phase_days_qci0
#endif
  end if
! make sure all MPI tasks are aware of the same value:
#ifdef SPMD
  call mpibcast(period_days_qci0, 1, mpir8, 0, mpicom)
#endif
#ifdef MICDEBUG
    write (6,*) 'YO proc =',iam,' got period=',period_days_qci0,',phase=',phase_days_qci0
#endif

end subroutine init_micro_vary

subroutine update_micro_vary_vals  (glob_nstep,lchnk,icol)
  integer, intent(in) :: glob_nstep
  integer, intent (in) :: lchnk, icol
  real, parameter :: central_qci0 = 1.e-4
  real, parameter :: amp_qci0 = 0.5e-4
  real(r8) :: currday 

  if (glob_nstep .eq. 1) then
#ifdef MICDEBUG
    write (6,*) 'YO masterproc but lchnk,begchunk,icol=',lchnk,begchunk,icol
#endif
    if ( lchnk .eq. begchunk .and. icol .eq. 1 ) then
    call init_micro_vary()
    endif
  end if 

  currday = glob_nstep*get_step_size()/24./3600.

  ! Update sinusoidally varying in time microphysics parameters:
  qci0 = central_qci0 + amp_qci0*sin( (currday-phase_days_qci0)/period_days_qci0*2.*3.14159)
#ifdef MICDEBUG
  write (6,*) 'HEY iam=',iam,', qci0=',qci0
#endif
end subroutine update_micro_vary_vals

end module micro_vary
#endif
