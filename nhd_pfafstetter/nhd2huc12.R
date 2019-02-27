library(sf)
library(dplyr)
library(tictoc)
library(data.table)
source("/Users/mac414/analysis/poly2poly_R/area_weighted.R")

# define files/paths
wbd_gdb  <- "/Users/mac414/geospatial_data/HUC/HUC_geopackage/huc12_conus.gpkg"
nhd_path <- "/Users/mac414/geospatial_data/NHD_Plus/ancillary_data/nhdPlus_geopackage/"
map_path <- "/Users/mac414/geospatial_data/NHD_Plus/ancillary_data/nhdPlus_HUC12_mapping/"

# define projection
proj <- 5070

# define data table
nhdInfo <- data.table(
           region = c('MS' ,'MS' ,'MS' ,'MS' ,'MS' ,'MS' ,'TX' ,'RG' ,'CO' ,'MA' ,'PN' ,'CO' ,'GB' ,'SR' ,'CA' ,'NE' ,'MA' ,'SA' ,'SA' ,'GL' ,'MS' ,'SA'),
           code   = c('05' ,'06' ,'07' ,'08' ,'10L','11' ,'12' ,'13' ,'15' ,'02' ,'17' ,'14' ,'16' ,'09' ,'18' ,'01' ,'02' ,'03W','03S','04' ,'10U','03N'))

# read HUC-12 polygons
tic("read the HUC-12 polygons")
wbd <- read_sf(wbd_gdb, "huc12") %>%
               st_transform(proj) %>%
               st_buffer(0) %>%
               select(HUC12)
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
 tic("intersect NHD catchments and HUC12 polygons")
 intersected <- area_weighted_intersection(nhd, wbd)
 toc()  # print timing

 # write intercetions
 outputName <- paste(map_path, layerName, "_HUC12_intersection.tsv", sep="")
 readr::write_tsv(intersected, outputName)

 # stop and explore
 # stop

}  # looping through the data table
