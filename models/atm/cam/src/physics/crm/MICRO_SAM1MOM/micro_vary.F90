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

real(r8) :: period_days_qci0 = 5.0 ! dummy init, actually chosen randomly below(applies to all)
real(r8) :: phase_days_qci0 = 1.0

real(r8) :: period_days_qcw0 = 5.0
real(r8) :: phase_days_qcw0 = 1.0

contains

subroutine init_micro_vary
! Set the random period and phase offset for each sinusoidal variation of
! microphysics...
real :: x
  if (masterproc) then
    call random_seed()
    call random_number (x)
    period_days_qci0 = x*5.0 + 5.0 ! 5-10 day period, randomly chosen.
    call random_number (x)
    phase_days_qci0 = x*period_days_qci0 ! randomly initiated phase.
    call random_number (x)
    period_days_qcw0 = x*5.0 + 5.0 ! 5-10 day period, randomly chosen.
    call random_number (x)
    phase_days_qcw0 = x*period_days_qci0 ! randomly initiated phase.
#ifdef MICDEBUG
    write (6,*) 'YO masterproc chose period=',period_days_qci0,',phase=',phase_days_qci0
#endif
  end if
! make sure all MPI tasks are aware of the same value:
#ifdef SPMD
  call mpibcast(period_days_qci0, 1, mpir8, 0, mpicom)
  call mpibcast(period_days_qcw0, 1, mpir8, 0, mpicom)
  call mpibcast(phase_days_qci0, 1, mpir8, 0, mpicom)
  call mpibcast(phase_days_qcw0, 1, mpir8, 0, mpicom)
#endif
  write (6,*) 'MICROVARY qci0',iam,' got period=',period_days_qci0,',phase=',phase_days_qci0
  write (6,*) 'MICROVARY qcw0',iam,' got period=',period_days_qcw0,',phase=',phase_days_qcw0

end subroutine init_micro_vary

subroutine update_micro_vary_vals  (glob_nstep,lchnk,icol)
  integer, intent(in) :: glob_nstep
  integer, intent (in) :: lchnk, icol
! Parishani et al. 2019 varied qci0 between 5e-6 and 1e-4
  real, parameter :: central_qci0 = 5.e-5
!  real, parameter :: amp_qci0 = 1e-5 ! should give us twice that range.
  real, parameter :: amp_qci0 = 2.5e-5 ! actually I want more

! Parishani et al. 2019 varied qcw0 between 1e-3 and 1e-4
  real, parameter :: central_qcw0 = 5.e-4
!  real, parameter :: amp_qcw0 = 1e-4 ! should give us twice that range.
  real, parameter :: amp_qcw0 = 2.5e-4 ! actually I want more.

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
  qci0 = central_qci0 + amp_qci0*sin( (currday+phase_days_qci0)/period_days_qci0*2.*3.14159)
  qcw0 = central_qcw0 + amp_qcw0*sin( (currday+phase_days_qcw0)/period_days_qcw0*2.*3.14159)
#ifdef MICDEBUG
  write (6,*) 'HEY iam=',iam,', qci0=',qci0
#endif
end subroutine update_micro_vary_vals

end module micro_vary
#endif
