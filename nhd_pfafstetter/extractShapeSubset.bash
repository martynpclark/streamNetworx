#!/bin/bash
#
# used to extract a subset of shapefiles

# define directories
pathBase=/Users/mac414/geospatial_data/NHD_Plus/ancillary_data
pathOrig=${pathBase}/nhdPlus_SHPs_HDMA-HUC12

# define new path
pathNew=${pathBase}/nhdPlus_test
mkdir -p $pathNew

#
# HUC-12
########

# define directories
layerName=WBDHU12
pathHUC=/Users/mac414/geospatial_data/HUC/WBD_04_HU2_Shape
fileHUC=${pathHUC}/${layerName}.shp
fileGPG=${pathNew}/${layerName}_REG04.gpkg

# create a geopackage from HUC-12
ogr2ogr -f GPKG $fileGPG $fileHUC 2>> log.txt

#
# NHD+
######

for i in {1..9}
do

# define subset
subset=36${i}

# define file
layerName=Catchment_GL_04
fileOrig=${pathOrig}/${layerName}.shp
fileNew=${pathNew}/${layerName}_HDMA${subset}.shp
fileGPG=${pathNew}/${layerName}_HDMA${subset}.gpkg

# create subset from NHD+
ogrCommand='ogr2ogr -sql "SELECT * FROM '${layerName}" WHERE (HDMA LIKE '"${subset}"%')"'"'
eval "$ogrCommand" $fileNew $fileOrig 2> log1.txt
echo "$ogrCommand"
echo $fileOrig
echo $fileNew

# create a geopackage from NHD+
ogr2ogr -f GPKG $fileGPG $fileNew 2>> log2.txt

done

