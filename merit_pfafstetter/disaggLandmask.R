library(sf)
library(dplyr)
library(tictoc)

#' disaggLandmask.R
#' @description Disaggregate landmask in to separate polygons
disaggLandmask <- function(landmaskNames) {

# arguments
# landmaskNames = structure of names for the landmask 

# logical definitions
yes <- 1
no  <- 0

# check if we need to disaggregate
isDisaggregate <- no

# check if need to disaggregate
if(isDisaggregate == yes){

 tic("reading landmask")
 landmask <- read_sf(landmaskNames$landmask_shp)
 toc()  # print timing

 tic("disaggregate polygons into separated polygons")
 landtemp <- landmask %>% group_by(OBJECTID) %>% summarize(do_union = FALSE) %>% st_cast("MULTIPOLYGON")
 landmass <- landtemp %>% group_by(OBJECTID) %>% summarize(do_union = FALSE) %>% st_cast("POLYGON")
 landmass <- cbind(FID=rownames(landmass), landmass)
 landmass <- landmass %>% st_buffer(0) # trick to clean up invalid polygons
 toc()  # print timing

 tic("write separated polygons")
 write_sf(landmass, landmaskNames$landPolygons_shp)
 toc()  # print timing

} else {

 tic("reading landmask")
 landmass <- read_sf(landmaskNames$landPolygons_shp)
 toc()  # print timing

} # if need to disaggregate the shapefile

# end of function
return(landmass)
}
