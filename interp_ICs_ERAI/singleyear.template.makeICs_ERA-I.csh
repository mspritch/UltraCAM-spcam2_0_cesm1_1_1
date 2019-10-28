#! /bin/csh -f
#SBATCH -J icYYYY
#SBATCH -o log.YYYY.o%j       
#SBATCH -e err.YYYY.e%j
#SBATCH -p normal
#SBATCH -N 1 
#SBATCH -n 1
#SBATCH -t 01:59:00
#SBATCH --mail-user=mspritch@uci.edu
#SBATCH --mail-type=all    
#SBATCH -A TG-ATM190002
#-----------------------------------
# Written in Jun 2012 by Jerry Olson
#-----------------------------------

#set echo

# Set temporary directories for input and output analysis files
module load ncl_ncarg 

setenv MYTMPDIR               $SCRATCH/IC_scratch
set ref_file = $MYTMPDIR/ref_file_1.9x2.5_L30.nc
setenv MYTMPDIRO              $SCRATCH/ERAI_ICs_interp_1.9x2.5xL30

# Build fortran library
# (only needs doing once)
#WRAPIT         MAKEIC.stub MAKEIC.f90

set yyyy="YYYY"
set monthlengths = ( 31 28 31 30 31 30 31 31 30 31 30 31 )
foreach imonth ( `seq 1 12` )
set mm = `printf %02d $imonth`

set max_simul = 26
set count = 0
foreach iday ( `seq 1 $monthlengths[$imonth]` )
  set dd = `printf %02d $iday`
  foreach hourz ( 00 06 12 18 )
@ secs = ${hourz} * 3600
    set sssss = `printf %05d $secs`
    setenv REF_DATE               ${yyyy}${mm}${dd}

     #foreach sssss ( 00000 21600 43200 64800 )
# Output file format

setenv CASE                    ERAI_1.9x2.5_L30_${REF_DATE}  # Case name that will be appended to name of output file
setenv DYCORE                 fv       # Dycore ("eul" or "fv" are the current choices)
setenv PRECISION              float     # "double" or "float" are the current choices of output precision
setenv PTRM                    42       # "M" spectral truncation (for "eul" dycore only; ignored for other dycores; "-1" = no trunc)
setenv PTRN                    42       # "N" spectral truncation (for "eul" dycore only; ignored for other dycores; "-1" = no trunc)
setenv PTRK                    42       # "K" spectral truncation (for "eul" dycore only; ignored for other dycores; "-1" = no trunc)
#setenv PLAT                    64       # Number of latitudes  on output IC file
#setenv PLON                   128       # Number of longitudes on output IC file
setenv PLAT                    96       # Number of latitudes  on output IC file
setenv PLON                   144       # Number of longitudes on output IC file
setenv PLEV                    30       # Number of vert levs  on output IC file
                                        # (if PLEV = 0, no vertical levels will be generated in file)

# File from which to pull hyai, hybi, hyam, hybm info to define OUPUT levels (must be a CAM file or a file with level info in CAM format)

setenv FNAME_lev_info         $ref_file

# List of full input file pathnames (disk or HPSS) from which to pull fields to be regridded
# (up to 6 files)

setenv FNAME0                 $SCRATCH/ERAI-raw/${yyyy}${mm}/ei.oper.an.ml.regn128sc.${yyyy}${mm}${dd}${hourz} 
setenv FNAME1
setenv FNAME2
setenv FNAME3
setenv FNAME4
setenv FNAME5

# Regrid ALL input fields, if the first input file is a CAM file (otherwise, just regrid the fields listed below)

setenv REGRID_ALL             False

# Time slice to pull from each file (YYYYMMDDSSSSS or time index (0, 1, 2, 3, etc.))

setenv FDATE                  ${yyyy}${mm}${dd}${sssss}  

# List of CAM fields to be regridded (must contain, at minimum, U, V [or US and VS, if fv dycore], T, Q, and PS fields )

setenv FIELDS                 US,VS,T,Q,PS

# Input analysis file index in which each field can be found

setenv SOURCE_FILES           0,0,0,0,0

## Input file type (The "FTYPE" list maps to the above list of filenames)

##---------------------------------------------------------------------------------
## Current input file types:    CAM
##                              YOTC_PS_Z
##                              YOTC_sfc
##                              YOTC_sfc_fcst
##                              YOTC_sh
##                              ECMWF_gg
##                              ECMWF_sh
##                              NASA_MERRA
##                              NASA_MERRA_PREVOCA
##                              JRA_25
##                              Era_Interim_627.0_sc
##                              ERA40_ds117.2
##---------------------------------------------------------------------------------

setenv FTYPE                   Era_Interim_627.0_sc

# Adjust PS and near-surface T based on differences between input and output topography (PHIS)

setenv ADJUST_STATE_FROM_TOPO True

# File from which to pull input topography (PHIS) for use in T and Ps adjustment near surface

setenv FNAME_phis_input       $FNAME0
setenv FTYPE_phis_input       Era_Interim_627.0_sc 

# CAM File from which to pull output topography (PHIS; must already be on output grid) for use in T and Ps adjustment near surface

setenv FNAME_phis_output      $ref_file
setenv FTYPE_phis_output      CAM

# Processing options

setenv VORT_DIV_TO_UV         True      # U/V determined from vort/div input
setenv SST_MASK               False     # Use landfrac and icefrac masks to isolate and interpolate SSTs from Ts
                                        # (ignored if "SST_cpl" is not being output)
setenv ICE_MASK               False     # Use landfrac to isolate and interpolate ice fraction
                                        # (ignored if "ice_cov" is not being output)
setenv OUTPUT_PHIS            True      # Copy output PHIS to the output initial file.

setenv FNAME                  $FNAME0#,$FNAME1,$FNAME2,$FNAME3,$FNAME4,$FNAME5

ncl < ./makeIC.ncl  &
@ count = $count + 1
echo $count
if ( $count == $max_simul ) then
  wait
  set count = 0
endif
end # loop over time of day
end # loop over day
end # loop over month
exit
