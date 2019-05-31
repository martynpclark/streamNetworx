library(sf)
library(dplyr)
library(tictoc)

#' getLandmaskRegion
#' @description Obtain shapefile of landmask for a specified region
getLandmaskRegion <- function(landmaskNames, shapes) {

# arguments
# landmaskNames = structure of names for the landmask 
# shapes        = shapefile to define the bounding box 

# logical definitions
yes <- 1
no  <- 0

# check if we need to disaggregate
isDisaggregate <- yes

# check if we need to get the regional subset
isRegionSubset <- yes

# -----
# * disaggregate land mask into separated polygons...
# ---------------------------------------------------

if(isDisaggregate == yes){

 tic("reading landmask")
 landmask <- read_sf(landmaskNames$landmask_shp)
 toc()  # print timing

 tic("disaggregate polygons into separated polygons")
 landmask <- st_cast(landmask, "MULTIPOLYGON") %>% st_cast("POLYGON")
 toc()  # print timing

 tic("write separated polygons")
 write_sf(landmask, landmaskNames$landPolygons_shp)
 toc()  # print timing

} else {

 if(isRegionSubset == yes){
  tic("reading landmask")
  landmask <- read_sf(landmaskNames$landPolygons_shp)
  toc()  # print timing
 } # if we need the disaggregated landmask to compute the regional subset

} # if need to disaggregate the shapefile

# -----
# * get the regional landmask...
# ------------------------------

if(isRegionSubset == yes){



 %>% st_transform(st_crs(shapes)$epsg)


 # get the region
 buffer <- 1e4 # 10 km buffer
 region <- st_as_sfc(st_bbox(shapes)) %>% st_buffer(buffer) 

 tic("get the spatial subset within the bounding box")
 landmask <- st_intersection(landmask, region)
 toc()  # print timing

 # convert MULTIPOLYGONS to POLYGONS
 landmask <- st_cast(landmask, "MULTIPOLYGON") %>% st_cast("POLYGON")

 # compute the polygon area
 landmask <- cbind(area=st_area(landmask), landmask)

 tic("sort the polygon area (largest to smallest)")
 landmask <- landmask[order(-landmask$area),]
 toc()  # print timing

 # define the feature ID
 row.names(landmask) <- NULL  # reset to 1,2,3,...,n
 landmask$FID <- rownames(landmask)

 # remove all columns EXCEPT for the feature ID and area
 landmask <- landmask[ , c("FID", "area")]

 tic("write spatial subset")
 write_sf(landmask, landmaskNames$regionLandPoly_shp)
 toc()  # print timing

} else {

 tic("reading landmask")
 landmask <- read_sf(landmaskNames$regionLandPoly_shp)
 toc()  # print timing

} # if need regional subset

# end of function
return(landmask)
}
