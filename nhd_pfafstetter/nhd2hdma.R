library(sf)
library(dplyr)
library(tictoc)
library(data.table)
source("/Users/mac414/analysis/poly2poly_R/area_weighted.R")

# define files/paths
hdma_gdb <- "/Users/mac414/geospatial_data/HDMA/catch/na_catch.gpkg"
nhd_path <- "/Users/mac414/geospatial_data/NHD_Plus/ancillary_data/nhdPlus_geopackage/"
map_path <- "/Users/mac414/geospatial_data/NHD_Plus/ancillary_data/nhdPlus_HDMA_mapping/"

# define projection
proj <- 5070

# define data table
nhdInfo <- data.table(
           region = c('MS' , 'SA','PN' ,'CO' ,'GB' ,'SR' ,'CA' ,'NE' ,'MA' ,'SA' ,'SA' ,'GL' ,'MS' ,'MS' ,'MS' ,'MS' ,'MS' ,'MS' ,'TX' ,'RG' ,'CO' ,'MA' ),
           code   = c('10U','03N','17' ,'14' ,'16' ,'09' ,'18' ,'01' ,'02' ,'03W','03S','04' ,'05' ,'06' ,'07' ,'08' ,'10L','11' ,'12' ,'13' ,'15' ,'02' ))

# read HDMA polygons
tic("read the HDMA polygons")
hdma <- read_sf(hdma_gdb, "na_catch") %>%
                st_transform(proj) %>%
                st_buffer(0) %>%
                select(PFAF_CODE)
toc()  # print timing

# loop through data table
for (i in 1:nrow(nhdInfo)) {

 # define the filename
 layerName <- paste("Catchment_", nhdInfo$region[i], "_", nhdInfo$code[i], sep="")
 fileName  <- paste(nhd_path, layerName, ".gpkg", sep="")
 print(fileName)

 # read NHD+ catchments
 tic("read the NHD+ catchments")
 nhd <- read_sf(fileName, layerName) %>%
               st_transform(proj) %>%
               st_buffer(0) %>%
               select(COMID = FEATUREID)
 toc()  # print timing

 # intersect catchments
 tic("intersect NHD catchments and HDMA polygons")
 intersected <- area_weighted_intersection(nhd, hdma)
 toc()  # print timing

 # write intercetions
 outputName <- paste(map_path, layerName, "_HDMA_intersection.tsv", sep="")
 readr::write_tsv(intersected, outputName)

 # stop and explore
 stop

}  # looping through the data table
