module micro_params

use crm_grid, only: nzm

implicit none

!  Microphysics stuff:

! Densities of hydrometeors

real, parameter :: rhor = 1000. ! Density of water, kg/m3
real, parameter :: rhos = 100.  ! Density of snow, kg/m3
real, parameter :: rhog = 400.  ! Density of graupel, kg/m3
!real, parameter :: rhog = 917.  ! hail - Lin 1983    

! Temperatures limits for various hydrometeors

! hparish is following Marat's suggestion in changing the tbgmin to 258.16
! to test if this reduces the excessive extratropical cloud ice.
! default is: tbgmin = 253.16
! default is: tbgmax = 273.16 
real, parameter :: tbgmin = 253.16    ! Minimum temperature for cloud water., K
real, parameter :: tbgmax = 273.16    ! Maximum temperature for cloud ice, K
real, parameter :: tprmin = 268.16    ! Minimum temperature for rain, K
real, parameter :: tprmax = 283.16    ! Maximum temperature for snow+graupel, K
real, parameter :: tgrmin = 223.16    ! Minimum temperature for snow, K
real, parameter :: tgrmax = 283.16    ! Maximum temperature for graupel, K

! Terminal velocity coefficients

real, parameter :: a_rain = 842. ! Coeff.for rain term vel 
real, parameter :: b_rain = 0.8  ! Fall speed exponent for rain
real, parameter :: a_snow = 4.84 ! Coeff.for snow term vel
real, parameter :: b_snow = 0.25 ! Fall speed exponent for snow
!real, parameter :: a_grau = 40.7! Krueger (1994) ! Coef. for graupel term vel
real, parameter :: a_grau = 94.5 ! Lin (1983) (rhog=400)
!real, parameter :: a_grau = 127.94! Lin (1983) (rhog=917)
real, parameter :: b_grau = 0.5  ! Fall speed exponent for graupel

! Autoconversion

! hparish is changing the qcw0 threshold following Marat's suggestion to test hypothesis with regards to excessive ITCZ cloud water.
! the default value is: qcw0 = 1.e-3 
real, parameter :: qcw0 = 1.e-3      ! Threshold for water autoconversion, g/g  

! hparish is changing the qci0 threshold following Marat's suggestion to test hypothesis with regards to excessive cloud ice.
! the default value is: qci0 = 1.e-4 
real, parameter :: qci0 = 1.e-4     ! Threshold for ice autoconversion, g/g
real, parameter :: alphaelq = 1.e-3  ! autoconversion of cloud water rate coef
! HP and MSP concluded that the excess tropospheric ice in UP can be solved by tuning,
! therefore hparish is changing the autoconversioin coeff. in the next line to test the model sensitivity. June 2017.
! the default value is: betaelq = 1.e-3
real, parameter :: betaelq = 1.e-3   ! autoconversion of cloud ice rate coef

! Accretion

real, parameter :: erccoef = 1.0   ! Rain/Cloud water collection efficiency
real, parameter :: esccoef = 1.0   ! Snow/Cloud water collection efficiency
real, parameter :: esicoef = 0.1   ! Snow/cloud ice collection efficiency
real, parameter :: egccoef = 1.0   ! Graupel/Cloud water collection efficiency
real, parameter :: egicoef = 0.1   ! Graupel/Cloud ice collection efficiency

! Interseption parameters for exponential size spectra

real, parameter :: nzeror = 8.e6   ! Intercept coeff. for rain  
real, parameter :: nzeros = 3.e6   ! Intersept coeff. for snow
real, parameter :: nzerog = 4.e6   ! Intersept coeff. for graupel
!real, parameter :: nzerog = 4.e4   ! hail - Lin 1993 

real, parameter :: qp_threshold = 1.e-8 ! minimal rain/snow water content


! Misc. microphysics variables

real*4 gam3       ! Gamma function of 3
real*4 gams1      ! Gamma function of (3 + b_snow)
real*4 gams2      ! Gamma function of (5 + b_snow)/2
real*4 gams3      ! Gamma function of (4 + b_snow)
real*4 gamg1      ! Gamma function of (3 + b_grau)
real*4 gamg2      ! Gamma function of (5 + b_grau)/2
real*4 gamg3      ! Gamma function of (4 + b_grau)
real*4 gamr1      ! Gamma function of (3 + b_rain)
real*4 gamr2      ! Gamma function of (5 + b_rain)/2
real*4 gamr3      ! Gamma function of (4 + b_rain)
      
real accrsc(nzm),accrsi(nzm),accrrc(nzm),coefice(nzm)
real accrgc(nzm),accrgi(nzm)
real evaps1(nzm),evaps2(nzm),evapr1(nzm),evapr2(nzm)
real evapg1(nzm),evapg2(nzm)
            
real a_bg, a_pr, a_gr 


end module micro_params
