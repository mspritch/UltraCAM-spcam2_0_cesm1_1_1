#!/bin/csh
foreach year ( `seq 2003 2007` ) 
  cat singleyear.template.makeICs_ERA-I.csh | sed "s@YYYY@${year}@g" > tmpjob.$year.csh
  sbatch tmpjob.$year.csh
end
