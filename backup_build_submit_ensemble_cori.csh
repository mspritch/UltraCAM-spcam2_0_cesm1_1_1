#!/bin/csh

set days   = {01,04,07,10,13,16,19,22,25,28}
set months = {10,10,10,10,10,10,10,10,10,10}

@ num = 1
set run_time       = 02:25:00
set queue          = regular
set priority       = premium 
set account        = m2222
set Np             = 1024
set Np_else        = 256

while ($num < 11)
        #set run_start_date="2008-10-15"
	set run_start_date = "2008-$months[$num]-$days[$num]"
	set MMDD           = "$months[$num]$days[$num]"
        set start_tod      = "43200"

	set NL   = "125"
	set name = "p4_4x_ens_2deg_SAM1m_32x1CRM250m_10mrad_36h_L{$NL}_200810$days[$num]_12Z_$num"

	## ====================================================================
	#   define case
	## ====================================================================

	setenv CCSMTAG     UltraCAM-spcam2_0_cesm1_1_1
	setenv CASE        "$name"
	setenv CASESET     F_AMIP_SPCAM_sam1mom 
	setenv CASERES     f19_g16 
	setenv PROJECT     m2222

	## ====================================================================
	#   define directories
	## ====================================================================

	setenv MACH      corip1 
	setenv CCSMROOT  $HOME/$CCSMTAG
	setenv CASEROOT  $HOME/cases/$CASE
	setenv PTMP      $CSCRATCH
	setenv RUNDIR    $PTMP/$CASE/run
	setenv ARCHDIR   $PTMP/archive/$CASE
	setenv DATADIR   /global/project/projectdirs/PNNL-PJR/csm/inputdata
#$CSCRATCH/inputdata
	setenv DIN_LOC_ROOT_CSMDATA $DATADIR

	## ====================================================================
	#   create new case, configure, compile and run
	## ====================================================================

	rm -rf $CASEROOT 
	rm -rf $PTMP/$CASE

	#------------------
	## create new case
	#------------------
	
	cd  $CCSMROOT/scripts

	./create_newcase -case $CASEROOT -mach $MACH -res $CASERES -compset $CASESET -compiler intel -v

	#------------------
	## set environment
	#------------------

	cd $CASEROOT

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

	./xmlchange  -file env_run.xml -id  CONTINUE_RUN  -val 'FALSE'
	./xmlchange  -file env_run.xml -id  RESUBMIT      -val '0'
	./xmlchange  -file env_run.xml -id  STOP_N        -val '36'
	./xmlchange  -file env_run.xml -id  STOP_OPTION   -val 'nhours'
	./xmlchange  -file env_run.xml -id  REST_N        -val '12'
	./xmlchange  -file env_run.xml -id  REST_OPTION   -val 'nhours'
	./xmlchange  -file env_run.xml -id  DOUT_L_MS     -val 'FALSE'
	./xmlchange  -file env_run.xml -id  RUN_STARTDATE -val $run_start_date
        ./xmlchange  -file env_run.xml -id  START_TOD     -val $start_tod
	./xmlchange  -file env_run.xml -id  DIN_LOC_ROOT  -val $DATADIR
	./xmlchange  -file env_run.xml -id  DOUT_S_ROOT   -val $ARCHDIR
	./xmlchange  -file env_run.xml -id  RUNDIR        -val $RUNDIR

        ./xmlchange  -file env_run.xml -id  ATM_NCPL      -val '288'

cat <<EOF >! user_nl_cam

&camexp
npr_yz = 32,2,2,32
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
prescribed_aero_datapath = '$DATADIR/atm/cam/chem/trop_mozart_aero/aero'
prescribed_aero_file     = 'aero_1.9x2.5_L26_1850-2020_c130627.nc'
/

&prescribed_ozone_nl
prescribed_ozone_datapath = '$DATADIR/atm/cam/ozone'
!!prescribed_ozone_file     = 'ozone_1.9x2.5_L66_2005-2099_c130607.nc'
prescribed_ozone_file     = 'ozone_1.9x2.5_L26_1850-2015_rcp45_c101108.nc'
/

&solar_inparm
!!solar_data_file = '$DATADIR/atm/cam/solar/spectral_irradiance_Lean_1610-2140_ann_c100408.nc'
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

ncdata = '/global/u1/h/hparish/ICs/from_mike_YOTC/YOTC_interp_ICs_files/ens_1.9x2.5_L${NL}_2008${MMDD}_12Z_YOTC.cam2.i.$run_start_date-43200.nc'

dtime  = 300.
iradsw = 2
iradlw = 2

empty_htapes = .true.
fincl1 = 'TGCLDLWP:A','TGCLDIWP:A','PS:A','T:A','Q:A','RELHUM:A','FLUT:A','FSNTOA:A','FLNS:A','FSNS:A','FLNT:A','FSDS:A','FSNT:A','FSUTOA:A',
         'SOLIN:A','LWCF:A','SWCF:A','CLOUD:A','CLDICE:A','CLDLIQ:A','CLDTOT:A','CLDHGH:A','CLDMED:A','CLDLOW:A','OMEGA:A',
         'PRECT:A','U:A','V:A','LHFLX:A','SHFLX:A','SST:A','TS:A','PBLH:A',
         'TMQ:A','QAP:I','TAP:I','QBP:I','TBP:I','CLDLIQAP:I','CLDLIQBP:I',
         'Z3:A','CLDTOP:A','CLDBOT:A','PCONVB:A','PCONVT:A','FLDS:A','FLDSC:A',
         'CLOUDTOP:A','TIMINGF:A',
         'SPQRL:A','SPQRS:A','SPDT:A','SPDQ:A','SPDQC:A','SPDQI:A','SPMC:A','SPMCUP:A','SPMCDN:A','SPMCUUP:A','SPMCUDN:A','SPWW:A','SPBUOYA:A',
         'SPQC:A','SPQI:A','SPQS:A','SPQG:A','SPQR:A','SPQTFLX:A','SPUFLX:A','SPVFLX:A','SPTKE:A',
         'SPTKES:A','SPTK:A','SPQTFLXS:A','SPQPFLX:A','SPPFLX:A','SPQTLS:A','SPQTTR:A','SPQPTR:A','SPQPEVP:A','SPQPFALL:A','SPQPSRC:A','SPTLS:A'

nhtfrq   = 2,2
mfilt    = 6,6
/
EOF


cat <<EOF >! user_nl_clm

&clmexp
hist_empty_htapes = .true.
hist_fincl1 = 'QSOIL:A', 'QVEGE:A', 'QVEGT:A', 'QIRRIG:A', 'FCEV:A', 'FCTR:A', 'FGEV:A', 'H2OCAN:A', 'H2OSOI:A', 'QDRIP:A', 'QINTR:A', 'QOVER:A',
              'SOILICE:A', 'SOILLIQ:A', 'TSA:A', 'Q2M:A', 'RH2M:A'
hist_nhtfrq = -1
hist_mfilt  = 6
/
EOF

cat <<EOF >! user_nl_cice
stream_fldfilename = '/global/homes/h/hparish/ICs/SST_bc/for_F_AMIP/SSThacked_YOTC2008${MMDD}.nc'
EOF

	#------------------
	## configure
	#------------------

	config:
	cd $CASEROOT
	./cesm_setup
	./xmlchange -file env_build.xml -id EXEROOT -val $PTMP/p4_4x_exec_SAM1mom_MPD_32x1CRM250m_10mrad_L125_1024_256/bld
	./xmlchange -file env_build.xml -id BUILD_COMPLETE -val 'TRUE'

	echo "CESM_setup ran okay for ensemble member $num"	
	
	modify:
	cd $CASEROOT

#------------------
##  Interactively build the model
#------------------

#build:           #don't build because the executable is already built and this script is only building the ensemble off of that exec.
#cd $CASEROOT
#./$CASE.build 

	cd  $CASEROOT
	sed -i 's/^#SBATCH --time=.*/#SBATCH --time='$run_time' /' $CASE.run
	sed -i 's/^#SBATCH -p .*/#SBATCH -p '$queue' /' $CASE.run
	sed -i 's/^#SBATCH  --qos=.*/#SBATCH --qos='$priority' /' $CASE.run

	cd  $CASEROOT
	set bld_cmp   = `grep BUILD_COMPLETE env_build.xml`
	set split_str = `echo $bld_cmp | awk '{split($0,a,"="); print a[3]}'`
	set t_or_f    = `echo $split_str | cut -c 2-5`

if ( $t_or_f == "TRUE" ) then
    sbatch $CASE.run
    echo '-------------------------------------------------'
    echo '----Build and compile is GOOD, job submitted!----'
else
    set t_or_f = `echo $split_str | cut -c 2-6`
    echo 'Build not complete, BUILD_COMPLETE is:' $t_or_f
endif

	@ num++

end
