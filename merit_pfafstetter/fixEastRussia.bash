#!/bin/bash
#
# shift east russia from [-180-180] to [0-360]

# define original file
path=/Users/mac414/geospatial_data/MERIT-hydro/pfaf_level_02/
file=${path}riv_pfaf_35_MERIT_Hydro_v07_Basins_v01_bugfix1.shp
echo $file

# get layer
layer=$(basename ${file} .shp)
echo $layer

# get copy of the file
fileCopy=${path}${layer}_copy.shp
fileOrig=${path}${layer}_orig.shp
#ogr2ogr ${fileCopy} $file
#ogr2ogr ${fileOrig} $file

# get the select command
select='-dialect sqlite -sql "SELECT ShiftCoords(geometry,-180,0) FROM '$(basename ${fileOrig} .shp)'"'
echo "${select}"

# evaluate
eval ogr2ogr $file $fileOrig "${select}"
