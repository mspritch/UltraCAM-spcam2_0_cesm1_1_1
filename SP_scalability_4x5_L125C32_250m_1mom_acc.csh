#!/bin/csh
#SBATCH --job-name=build4x5scale
#SBATCH --time=00:30:00 
#SBATCH -N 2
#SBATCH --mail-type=END
###SBATCH --mail-user=xyz@abc.com
#SBATCH -p debug 
#SBATCH --license SCRATCH,project
#SBATCH -C haswell 

set thescales = ( 512 1024 2048 3072 )
set thenpelses = ( 128 256 512 512 )

foreach itest ( 1 2 3 4 )
  set thescale = $thescales[$itest]
  set Np_else = $thenpelses[$itest]

set run_time       = 00:55:00
set queue          = regular 
set priority       = premium 
set account        = m2222
set run_start_date = "2008-10-15"
set start_tod      = "00000"
#set start_tod      = "43200"
set Np             = ${thescale}

## ====================================================================
#   define case
## ====================================================================

setenv CCSMTAG     UltraCAM-spcam2_0_cesm1_1_1
#r2: default monthly output only
#r3: crm acceleration turned off in config_compilers.xml (since reverted)
#setenv CASE        scalabilityr2_${thescale}_1.9x2.5_L125C32_250m_1mom_acc4x
setenv CASE        scalability_hp3_4xacc_${thescale}_4x5_L125C32_250m_1mom
setenv CASESET     F_2000_SPCAM_sam1mom_UP
#setenv CASESET      F_2000_SPCAM_sam1mom_SP
#setenv CASERES     f09_g16
#setenv CASERES     f19_g16
setenv CASERES     f45_f45
setenv PROJECT     m2222

## ====================================================================
#   define directories
## ====================================================================

setenv MACH      corip1 
setenv CCSMROOT  $HOME/$CCSMTAG
setenv CASEROOT  $HOME/cases/$CASE
setenv PTMP      $SCRATCH
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
./xmlchange  -file env_run.xml -id  STOP_N        -val '24'
./xmlchange  -file env_run.xml -id  STOP_OPTION   -val 'nhours'
./xmlchange  -file env_run.xml -id  REST_N        -val '1'
./xmlchange  -file env_run.xml -id  REST_OPTION   -val 'ndays'       # 'nhours' 'nmonths' 'nsteps' 'nyears' 
./xmlchange  -file env_run.xml -id  DOUT_L_MS     -val 'FALSE'
./xmlchange  -file env_run.xml -id  RUN_STARTDATE -val $run_start_date
./xmlchange  -file env_run.xml -id  START_TOD     -val $start_tod
./xmlchange  -file env_run.xml -id  DIN_LOC_ROOT  -val $DATADIR
./xmlchange  -file env_run.xml -id  DOUT_S_ROOT   -val $ARCHDIR
./xmlchange  -file env_run.xml -id  RUNDIR        -val $RUNDIR

./xmlchange  -file env_run.xml -id  ATM_NCPL      -val '288'    

cat <<EOF >! user_nl_cam

&camexp
npr_yz = 8,2,2,8
!npr_yz = 32,2,2,32
prescribed_aero_model='bulk'
/

&aerodep_flx_nl
aerodep_flx_datapath           = '$DATADIR/atm/cam/chem/trop_mozart_aero/aero'
aerodep_flx_file               = 'aerosoldep_rcp2.6_monthly_1849-2104_1.9x2.5_c100402.nc'
/

&prescribed_volcaero_nl
prescribed_volcaero_datapath = '$DATADIR/atm/cam/volc'
prescribed_volcaero_file     = 'CCSM4_volcanic_1850-2011_prototype1.nc'
/

&prescribed_aero_nl
!!prescribed_aero_datapath = '/global/u1/h/hparish/ICs/aerosols'
!!prescribed_aero_file     = '5x_aero_1.9x2.5_L26_1850-2020_c130627.nc'
!!prescribed_aero_file     = '20x_aero_1.9x2.5_L26_1850-2020_c130627.nc'
prescribed_aero_datapath = '$DATADIR/atm/cam/chem/trop_mozart_aero/aero'
prescribed_aero_file     = 'aero_1.9x2.5_L26_1850-2020_c130627.nc'
/

&cam_inparm
phys_loadbalance = 2

!ncdata = '/global/u1/h/hparish/ICs/from_jerry/hp_interp_analyses/YOTC_interp_IC_files/1.9x2.5_L30_20081015_YOTC.cam2.i.2008-10-15-43200.nc'
ncdata = '/global/u1/h/hparish/ICs/from_mike_YOTC/YOTC_interp_ICs_files/4x5_L125_Sc1_20081015_YOTC.cam2.i.2008-10-15-00000.nc'

dtime  = 300. 
iradsw = 2 
iradlw = 2
!iradae = 4 

empty_htapes = .false.
fincl2 = 'TGCLDLWP:A','TGCLDIWP:A','PS:A','T:A','Q:A','RELHUM:A','FLUT:A','FSNTOA:A','FLNS:A','FSNS:A','FLNT:A','FSDS:A','FSNT:A','FSUTOA:A','SOLIN:A','LWCF:A','SWCF:A','CLOUD:A','CLDICE:A','CLDLIQ:A','CLDTOT:A','CLDHGH:A','CLDMED:A','CLDLOW:A','OMEGA:A','OMEGA500:A','PRECT:A','U:A','V:A','LHFLX:A','SHFLX:A','SST:A','TS:A','PBLH:A','TMQ:A','Z3:A','CLDTOP:A','CLDBOT:A','FLDS:A','FLDSC:A','FSDSC:A','FSNSC:A','FSNTC:A','FSNTOAC:A','FLNSC:A','FLNTC:A','FLUTC:A','QRL:A','QRS:A','CLOUDTOP:A','TIMINGF:A','SPQC:A','SPQI:A','SPQS:A','SPQG:A','SPQR:A'
fincl3 = 'PS:A','SPMC:A','SPMCUP:A','SPMCDN:A','SPMCUUP:A','SPMCUDN:A','SPWW:A','SPBUOYA:A','SPQTFLX:A','SPTKE:A','SPTKES:A','SPTK:A','SPQTFLXS:A','SPQPFLX:A','SPPFLX:A','SPQTLS:A','SPQTTR:A','SPQPTR:A','SPQPEVP:A','SPQPFALL:A','SPQPSRC:A','SPTLS:A'
fincl4 = 'PS:A','QAP:I','TAP:I','QBP:I','TBP:I','CLDLIQAP:I','CLDLIQBP:I','DTCORE:A','PTTEND:A','PTEQ:A','SPDT:A','SPDQ:A','DTV:A','VD01:A','SHFLX:A','LHFLX:A','QRL:A','QRS:A','T:A','U:A','V:A','OMEGA:A','Q:A','VT:A','VU:A','VV:A','VQ:A','UU:A','OMEGAT:A'
nhtfrq = 0,-1,-2,-6
mfilt  = 1,24,12,4
/
EOF

cat <<EOF >! user_nl_clm

&clmexp
hist_empty_htapes = .false.
hist_fincl1 = 'QSOIL:A', 'QVEGE:A', 'QVEGT:A', 'QIRRIG:A', 'FCEV:A', 'FCTR:A', 'FGEV:A', 'H2OCAN:A', 'H2OSOI:A', 'QDRIP:A', 'QINTR:A', 'QOVER:A','SOILICE:A', 'SOILLIQ:A', 'TSA:A', 'Q2M:A', 'RH2M:A'
hist_nhtfrq = -2
hist_mfilt  = 12
/
EOF

#------------------
## configure
#------------------

config:
cd $CASEROOT
./cesm_setup
./xmlchange -file env_build.xml -id EXEROOT -val $PTMP/$CASE/bld

modify:
cd $CASEROOT
#if (-e $mymodscam) then
#    ln -s $mymodscam/* SourceMods/src.cam
#endif
#------------------
##  Interactively build the model
#------------------

build:
cd $CASEROOT
./$CASE.build &

cd  $CASEROOT
sed -i 's/^#SBATCH --time=.*/#SBATCH --time='$run_time' /' $CASE.run
sed -i 's/^#SBATCH -p .*/#SBATCH -p '$queue' /' $CASE.run
sed -i 's/^#SBATCH --qos .*/#SBATCH --qos '$priority' /' $CASE.run
#sed -i 's/^#SBATCH -A .*/#SBATCH -A '$account' /' $CASE.run

#cd  $CASEROOT
#set bld_cmp   = `grep BUILD_COMPLETE env_build.xml`
#set split_str = `echo $bld_cmp | awk '{split($0,a,"="); print a[3]}'`
#set t_or_f    = `echo $split_str | cut -c 2-5`

#if ( $t_or_f == "TRUE" ) then
#    sbatch $CASE.run
#    echo '-------------------------------------------------'
#    echo '----Build and compile is GOOD, job submitted!----'
#else
#    set t_or_f = `echo $split_str | cut -c 2-6`
#    echo 'Build not complete, BUILD_COMPLETE is:' $t_or_f
#endif

end # end of foreach
wait
