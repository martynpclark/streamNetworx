#!/bin/bash
#
# get subset of big lakes

# define the hydroLakes path
lakePath=/Users/mac414/geospatial_data/hydroLakes/HydroLAKES_polys_v10_shp/

# define files
infile=HydroLAKES_polys_v10.shp
outfile=AfricaLakes_big.shp

# get the layer name
layerName=${infile%.*}

# define area threshold
threshold=50

# define continent
continent="'Africa'"

# identify the subset
subset="where (Lake_area > "${threshold}") and (Continent = "${continent}")"

# get the full command
ogrCommand='ogr2ogr -sql "SELECT * FROM '${layerName}' '${subset}'"'
echo "${ogrCommand}"

# run the command
eval "${ogrCommand}" ${lakePath}${outfile} ${lakePath}${infile} 2> log.txt

#ogr2ogr -sql "SELECT * FROM na_streams WHERE (PFAF_CODE > 396000000000) AND (PFAF_CODE < 397000000000)" na_streams_colorado.shp na_streams.shp


