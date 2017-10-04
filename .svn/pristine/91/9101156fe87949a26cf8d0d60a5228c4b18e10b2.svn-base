#! /bin/csh -f

## ROOT OF CAM DISTRIBUTION - probably needs to be customized.
## Contains the source code for the CAM distribution.
## (the root directory contains the subdirectory "models")
set camroot = ~/spcam1_5_00_cam5_1_24_pnnl

## ROOT OF CAM DATA DISTRIBUTION - needs to be customized unless running at NCAR.
## Contains the initial and boundary data for the CAM distribution.
## (the root directory contains the subdirectories "atm" and "lnd")

##setenv CSMDATA     /fs/cgd/csm/inputdata
##setenv CSMDATA $GSCRATCH/csmdata
setenv CSMDATA /project/projectdirs/ccsm1/inputdata

echo $CRAY_NETCDF_DIR
echo $CRAY_MPICH2_DIR
#setenv LIB_NETCDF    /usr/local/lib64/r4i4
#setenv INC_NETCDF    /usr/local/include
##setenv LIB_NETCDF    /usr/local/netcdf-4.1.3-pgi-hpf-cc-11.5-0/lib
##setenv INC_NETCDF    /usr/local/netcdf-4.1.3-pgi-hpf-cc-11.5-0/include

set curdir = `pwd`

## Default namelist settings:
## $case is the case identifier for this run.
set case  = test-m2005-4x5_V13

## $wrkdir is a working directory where the model will be built and run.
## $blddir is the directory where model will be compiled.
## $cfgdir is the directory containing the CAM configuration scripts.
#set wrkdir       = $TMPDIR
#set wrkdir       = /scratch/cluster/$LOGNAME
set TMPDIR      = $GSCRATCH
set wrkdir       = $TMPDIR/CASES_SPCAM
set blddir       = $wrkdir/$case/bld
set outputdir       = $wrkdir/$case/output
set cfgdir       = $camroot/models/atm/cam/bld
set rundir       = $HOME/mmf_cases/run_$case

##rm -fr  $blddir
##rm $blddir/cam

export LD_LIBRARY_PATH=\${LIB_NETCDF}:\${LD_LIBRARY_PATH}

# rm -fr  $blddir

## Ensure that build directory exists
mkdir -p $blddir || echo "cannot create $blddir" && exit 1
mkdir -p $outputdir  || echo "cannot create $blddir" && exit 1

## If an executable doesn't exist, build one.
if ( ! -x $blddir/cam ) then

  ## build executable
  cd $blddir || echo "cd $blddir failed" && exit 1

  echo "building CAM in $blddir ..."
  echo "Compilation starts on "`date`

  $cfgdir/configure -s \
        -fc ftn \
        -cc cc \
        -mpi_inc $CRAY_MPICH2_DIR/include \
        -mpi_lib $CRAY_MPICH2_DIR/lib \
        -nc_inc $INC_NETCDF \
        -nc_lib $LIB_NETCDF \
        -nc_mod $INC_NETCDF \
       -res 4x5\
#       -debug \
       -nosmp \
       -spmd \
       -ntask 4 \
##       -nospmd \
       -rad rrtmg \
       -chem trop_mam3 \
       -use_SPCAM \
       -crm_nx 32 \
       -crm_ny 1 \
       -crm_nz 28 \
       -crm_dx 4000 \
       -crm_dt 20  \
       -SPCAM_microp_scheme m2005 \
       -use_ECPP \
    || echo "configure failed" && exit 1

  gmake -j64 >&! MAKE.out      || echo "CAM build failed: see $blddir/MAKE.out" && exit 1
  
  echo "Compilation stops  on "`date`
endif

echo " "
echo "Create the namelist..."
echo " "
## Create the namelist
cd $blddir                      || echo "cd $blddir failed" && exit 1
pwd
echo $cfgdir
$cfgdir/build-namelist -case $case -runtype startup  \
 -namelist "&camexp  stop_n=2, dtime=600, stop_option='ndays' \
 start_ymd= 0101\
 npr_yz         = 8,4,4,8 \
 dust_emis_fact         = 4.2D0 \
/"  || echo "build-namelist failed" && exit 1

mv $blddir/*_in $rundir/
mv $blddir/docn.stream.txt $rundir/ 

echo " "
echo "build namelist complete"
echo " "

##

#/opt/toolworks/totalview.8.9.1-1/bin/totalview $blddir/cam             || echo "CAM run failed" && exit 1
##/home/cacraig/bin/toolworks/totalview $blddir/cam             || echo "CAM run failed" && exit 1
#$blddir/cam             || echo "CAM run failed" && exit 1

##cd $camroot/run
##./compare-sam1mom.sh

exit 0


