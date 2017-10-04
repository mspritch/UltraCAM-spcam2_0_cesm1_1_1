#! /bin/csh -f

## ROOT OF CAM DISTRIBUTION - probably needs to be customized.
## Contains the source code for the CAM distribution.
## (the root directory contains the subdirectory "models")
set camroot = /home/cacraig/spcam_cam5_2_00_forCESM1_1_0Rel

## ROOT OF CAM DATA DISTRIBUTION - needs to be customized unless running at NCAR.
## Contains the initial and boundary data for the CAM distribution.
## (the root directory contains the subdirectories "atm" and "lnd")

setenv CSMDATA     /fs/cgd/csm/inputdata

#setenv LIB_NETCDF    /usr/local/lib64/r4i4
#setenv INC_NETCDF    /usr/local/include
setenv LIB_NETCDF    /usr/local/netcdf-4.1.3-pgi-hpf-cc-11.5-0/lib
setenv INC_NETCDF    /usr/local/netcdf-4.1.3-pgi-hpf-cc-11.5-0/include

set curdir = `pwd`

## Default namelist settings:
## $case is the case identifier for this run.
set case  = test-m2005-clubb_SPCAM-CESM1_1_1

## $wrkdir is a working directory where the model will be built and run.
## $blddir is the directory where model will be compiled.
## $cfgdir is the directory containing the CAM configuration scripts.
#set wrkdir       = $TMPDIR
set wrkdir       = /scratch/cluster/$LOGNAME
set blddir       = $wrkdir/$case/bld
set cfgdir       = $camroot/models/atm/cam/bld

rm $blddir/test-sam1mom*
rm $blddir/cam

export LD_LIBRARY_PATH=\${LIB_NETCDF}:\${LD_LIBRARY_PATH}

# rm -fr  $blddir

## Ensure that build directory exists
mkdir -p $blddir || echo "cannot create $blddir" && exit 1

## If an executable doesn't exist, build one.
if ( ! -x $blddir/cam ) then

  ## build executable
  cd $blddir || echo "cd $blddir failed" && exit 1

  echo "building CAM in $blddir ..."
  echo "Compilation starts on "`date`

  $cfgdir/configure -s \
       -res 10x15\
       -debug \
       -nosmp \
       -nospmd \
       -rad rrtmg \
       -chem trop_mam3 \
       -use_SPCAM \
       -clubb_crm \
       -cppdefs -DNO_LAPACK_ISNAN \
       -crm_nx 16 \
       -crm_ny 1 \
       -crm_nz 28 \
       -crm_dx 4000 \
       -crm_dt 20  \
       -SPCAM_microp_scheme m2005 \
       -use_ECPP \
       -ldflags "-llapack -lblas -Mnobounds" \
    || echo "configure failed" && exit 1

  gmake -j8 >&! MAKE.out      || echo "CAM build failed: see $blddir/MAKE.out" && exit 1
  
  echo "Compilation stops  on "`date`
endif

echo " "
echo "Create the namelist..."
echo " "
## Create the namelist
cd $blddir                      || echo "cd $blddir failed" && exit 1
$cfgdir/build-namelist -case $case -runtype startup  \
 -namelist "&camexp  stop_n=10, nhtfrq=1, dtime=600, stop_option='nsteps' \
 start_ymd              = 0101 \
/"  || echo "build-namelist failed" && exit 1

echo " "
echo "build namelist complete"
echo " "

##

#/opt/toolworks/totalview.8.9.1-1/bin/totalview $blddir/cam             || echo "CAM run failed" && exit 1
#totalview $blddir/cam             || echo "CAM run failed" && exit 1
$blddir/cam             || echo "CAM run failed" && exit 1

cd $camroot/run
./compare-sam1mom.sh

exit 0


