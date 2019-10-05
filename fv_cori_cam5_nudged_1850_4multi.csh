#!/bin/csh

# This is the most general form of the build/submit script for SP/UP model.
# HP has also made other versions of this script for simpler model configurations.
# Questions? Please contact h.parish@uci.edu at UC Irvine ESS.

set run_time       = 02:00:00
set queue          = regular
set priority       = normal 
set account        = m3306
set run_start_date = "2009-07-01"
set start_tod      = "00000"
#set start_tod      = "43200"
set Np             = 1024 
set Np_else        = 256 

## ====================================================================
#   define case
## ====================================================================

setenv CCSMTAG     UltraCAM-spcam2_0_cesm1_1_1
setenv CASE        AeroPI_nudgEns11_4x5_cam5_L30_MultiRun_20090701_0Z_$Np
#setenv CASESET     F_AMIP_CAM5
#setenv CASESET     F_AMIP_SPCAM_sam1mom_shortcrm 
#setenv CASESET     F_2000_SPCAM_m2005_ECPP_PIaero
setenv CASESET     F_2000_mam3_PIaero
#setenv CASERES     f09_g16
#setenv CASERES     f19_g16
setenv CASERES     f45_f45
setenv PROJECT     m3306

## ====================================================================
#   define directories
## ====================================================================

setenv MACH      corip1 
setenv CCSMROOT  $HOME/UP/$CCSMTAG
setenv CASEROOT  $HOME/UP/cases/$CASE
setenv PTMP      $SCRATCH/UP
setenv RUNDIR    $PTMP/$CASE/run
setenv ARCHDIR   $PTMP/archive/$CASE
setenv DATADIR   /global/project/projectdirs/PNNL-PJR/csm/inputdata
setenv DIN_LOC_ROOT_CSMDATA $DATADIR
#setenv mymodscam $HOME/mymods/$CCSMTAG/CAM
#mkdir -p $mymodscam

## ====================================================================
#   create new case, configure, compile and run
## ====================================================================

rm -rf $CASEROOT
rm -rf $PTMP/$CASE
#rm -rf $PTMP/$CASE

#------------------
## create new case
#------------------

# set netcdf choice
module unload cray-netcdf/4.6.1.3
module load cray-netcdf/4.4.1.1.6


cd  $CCSMROOT/scripts

./create_newcase -case $CASEROOT -mach $MACH -res $CASERES -compset $CASESET -compiler intel -v

#------------------
## set environment
#------------------

cd $CASEROOT

#set ntasks = $Np
./xmlchange  -file env_mach_pes.xml -id  NTASKS_ATM  -val=$Np
./xmlchange  -file env_mach_pes.xml -id  NTASKS_LND  -val=$Np_else
./xmlchange  -file env_mach_pes.xml -id  NTASKS_ICE  -val=$Np_else
./xmlchange  -file env_mach_pes.xml -id  NTASKS_OCN  -val=$Np_else
./xmlchange  -file env_mach_pes.xml -id  NTASKS_CPL  -val=$Np_else
./xmlchange  -file env_mach_pes.xml -id  NTASKS_GLC  -val=$Np_else
./xmlchange  -file env_mach_pes.xml -id  NTASKS_ROF  -val=$Np_else
./xmlchange  -file env_mach_pes.xml -id  TOTALPES    -val=$Np

set-run-opts:
cd $CASEROOT

./xmlchange  -file env_run.xml -id  RESUBMIT      -val '0'
./xmlchange  -file env_run.xml -id  STOP_N        -val '42'
./xmlchange  -file env_run.xml -id  STOP_OPTION   -val 'ndays'
#./xmlchange  -file env_run.xml -id  REST_N        -val '6'
./xmlchange  -file env_run.xml -id  REST_OPTION   -val 'ndays'       # 'nhours' 'nmonths' 'nsteps' 'nyears' 
./xmlchange -file env_run.xml -id REST_N           -val '7'
./xmlchange  -file env_run.xml -id  RUN_STARTDATE -val $run_start_date
./xmlchange  -file env_run.xml -id  START_TOD     -val $start_tod
./xmlchange  -file env_run.xml -id  DIN_LOC_ROOT  -val $DATADIR
./xmlchange  -file env_run.xml -id  DOUT_S_ROOT   -val $ARCHDIR
./xmlchange  -file env_run.xml -id  RUNDIR        -val $RUNDIR

./xmlchange  -file env_run.xml -id  DOUT_S_SAVE_INT_REST_FILES     -val 'TRUE'
./xmlchange  -file env_run.xml -id  DOUT_L_MS                      -val 'FALSE'

./xmlchange  -file env_run.xml -id  ATM_NCPL              -val '48'    
#./xmlchange  -file env_run.xml -id  SSTICE_DATA_FILENAME  -val '$DATADIR/atm/cam/sst/sst_HadOIBl_bc_1x1_1850_2013_c140701.nc' 

cat <<EOF >! user_nl_cam

&camexp
npr_yz = 8,2,2,8
!npr_yz = 32,2,2,32
!prescribed_aero_model='bulk'
/

&aerodep_flx_nl
aerodep_flx_datapath           = '$DATADIR/atm/cam/chem/trop_mozart_aero/aero'
aerodep_flx_file               = 'aerosoldep_rcp2.6_monthly_1849-2104_1.9x2.5_c100402.nc'
/

&prescribed_volcaero_nl
prescribed_volcaero_datapath = '$DATADIR/atm/cam/volc'
prescribed_volcaero_file     = 'CCSM4_volcanic_1850-2011_prototype1.nc'
/


&solar_inparm
!solar_data_file = '$DATADIR/atm/cam/solar/spectral_irradiance_Lean_1610-2140_ann_c100408.nc'
solar_data_file = '$DATADIR/atm/cam/solar/spectral_irradiance_Lean_1950-2012_daily_Leap_c130227.nc'
/

&chem_surfvals_nl
bndtvghg = '$DATADIR/atm/cam/ggas/ghg_hist_1765-2012_c130501.nc'

ch4vmr = 1760.0e-9
co2vmr = 367.0e-6
f11vmr = 653.45e-12
f12vmr = 535.0e-12
n2ovmr = 316.0e-9
/




&cam_inparm
phys_loadbalance = 2

ncdata = '/global/project/projectdirs/m3306/terai/IC_files/L30_4x5/regrid_EI_4x5_L30.cam2.i.2009-07-01-00000.nc'

Nudge_Model = .true.
Nudge_Path = '/global/project/projectdirs/m3306/terai/IC_files/L30_4x5/'
Nudge_File_Template = 'regrid_EI_4x5_L30.cam2.i.%y-%m-%d-%s.nc'
Nudge_Times_Per_Day = 4
Model_Times_Per_Day = 48
Nudge_Uprof = 1
Nudge_Ucoef = 1.
Nudge_Vprof = 1
Nudge_Vcoef = 1.
Nudge_Tprof = 0
Nudge_Tcoef = 0.
Nudge_Qprof = 0
Nudge_Qcoef = 0.
Nudge_PSprof = 0
Nudge_PScoef = 0.
Nudge_Beg_Year = 2008
Nudge_Beg_Month = 01
Nudge_Beg_Day = 01
Nudge_End_Year = 2010
Nudge_End_Month = 10
Nudge_End_Day = 07

iradsw = 2 
iradlw = 2
!iradae = 4 

empty_htapes = .true.
!fincl1 = 'cb_ozone_c', 'MSKtem', 'VTH2d', 'UV2d', 'UW2d', 'U2d', 'V2d', 'TH2d', 'W2d', 'UTGWORO'
fincl1='cb_ozone_c'
fincl2 = 'TGCLDLWP:A','TGCLDIWP:A','PS:A','T:A','Q:A','RELHUM:A','FLUT:A','FSNTOA:A','FLNS:A','FSNS:A','FLNT:A','FSDS:A','FSNT:A','FSUTOA:A',
         'SOLIN:A','LWCF:A','SWCF:A','CLOUD:A','CLDICE:A','CLDLIQ:A','CLDTOT:A','CLDHGH:A','CLDMED:A','CLDLOW:A','OMEGA:A','OMEGA500:A',
         'PRECT:A','U:A','V:A','LHFLX:A','SHFLX:A','SST:A','TS:A','PBLH:A',
         'TMQ:A','QAP:I','TAP:I','QBP:I','TBP:I','CLDLIQAP:I','CLDLIQBP:I',
         'Z3:A','CLDTOP:A','CLDBOT:A','PCONVB:A','PCONVT:A','FLDS:A','FLDSC:A',
         'FSDSC:A','FSNSC:A','FSNTC:A','FSNTOAC:A','FLNSC:A','FLNTC:A','FLUTC:A','QRL:A','QRS:A',
         'AODVIS:A'

fincl3 = 'CCN1:A','CCN2:A','CCN3:A','CCN4:A','CCN5:A','CCN6:A','ICWNC:A','ICWMR:A','ICINC:A'

fincl4 = 'Nudge_V:A','Nudge_U:A'

fincl5 = 'AQRAIN:A','ANRAIN:A','TKE:A'

!fincl4 = 'SPQC:A','CLDACT_SS:A','CCN6:A','SPNC:A','ICWNC:A'

!fincl3 = 'SPQRL:A','SPQRS:A','SPDT:A','SPDQ:A','SPDQC:A','SPDQI:A','SPMC:A','SPMCUP:A','SPMCDN:A','SPMCUUP:A','SPMCUDN:A','SPWW:A','SPBUOYA:A',
!         'SPQC:A','SPQI:A','SPQS:A','SPQG:A','SPQR:A','SPQTFLX:A','SPUFLX:A','SPVFLX:A','SPTKE:A',
!         'SPTKES:A','SPTK:A','SPQTFLXS:A','SPQPFLX:A','SPPFLX:A','SPQTLS:A','SPQTTR:A','SPQPTR:A','SPQPEVP:A','SPQPFALL:A','SPQPSRC:A','SPTLS:A'

!fincl4 = 'PS:A','QAP:I','TAP:I','QBP:I','TBP:I','CLDLIQAP:I','CLDLIQBP:I','DTCORE:A','PTTEND:A','PTEQ:A','SPDT:A','SPDQ:A','DTV:A','VD01:A','SHFLX:A',
!         'LHFLX:A','QRL:A','QRS:A','T:A','U:A','V:A','OMEGA:A','Q:A','VT:A','VU:A','VV:A','VQ:A','UU:A','OMEGAT:A'

nhtfrq = 0,2,2,2,2
mfilt  = 0,6,6,6,6
/
EOF

cat <<EOF >! user_nl_clm
&clmexp
finidat = '/global/u1/h/hparish/ICs/ICs_from_Edison_scratch/NOSP_4x5_CTRL_eds_r2_25y_512.clm2.r.2025-01-01-00000.nc'

hist_empty_htapes = .true.
hist_fincl1 = 'QSOIL:A', 'QVEGE:A', 'QVEGT:A', 'QIRRIG:A', 'FCEV:A', 'FCTR:A', 'FGEV:A', 'H2OCAN:A', 'H2OSOI:A', 'QDRIP:A', 'QINTR:A', 'QOVER:A', 
              'SOILICE:A', 'SOILLIQ:A', 'TSA:A', 'Q2M:A', 'RH2M:A' 
hist_nhtfrq = -1
hist_mfilt  = 6 
/
EOF

cat <<EOF >! user_nl_cice
!stream_fldfilename = '$DATADIR/atm/cam/sst/sst_HadOIBl_bc_1x1_1850_2013_c140701.nc'
stream_fldfilename = '/global/project/projectdirs/PNNL-PJR/csm/inputdata/atm/cam/sst/sst_HadOIBl_bc_1x1_clim_c101029.nc'
EOF

#------------------
## configure
#------------------

config:
cd $CASEROOT
./cesm_setup
./xmlchange -file env_build.xml -id EXEROOT -val /global/cscratch1/sd/terai/UP/AeroPI_nudgEns11_4x5_cam5_L30_MultiRun_0Z_1024/bld
./xmlchange BUILD_COMPLETE=TRUE
