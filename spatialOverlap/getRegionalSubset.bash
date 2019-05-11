#!/bin/bash
#
# get subset of HDMA

# define the HDMA path
hdmaPath=/Users/mac414/geospatial_data/HDMA/streams/

# define files
infile=AF_streams.shp
outfile=AF_streams_nile.shp

# get the layer name
layerName=${infile%.*}

# define start and end Pfafstetter codes for the Colorado
#beg=396000000000  # 3 is North America; 96 is the Colorado
#end=397000000000  # 3 is North America; 96 is the Colorado

# define start and end Pfafstetter codes for the Nile
beg=220000000000  # 2 is Africa; 2 is the Nile
end=230000000000  # 2 is Africa; 2 is the Nile

# identify the subset
subset="where (PFAF_CODE > "${beg}") AND (PFAF_CODE < "${end}")"

# get the full command
ogrCommand='ogr2ogr -sql "SELECT * FROM '${layerName}' '${subset}'"'
echo "${ogrCommand}"

# run the command
eval "${ogrCommand}" ${hdmaPath}${outfile} ${hdmaPath}${infile} 2> log.txt

#ogr2ogr -sql "SELECT * FROM na_streams WHERE (PFAF_CODE > 396000000000) AND (PFAF_CODE < 397000000000)" na_streams_colorado.shp na_streams.shp


