library(sf)
library(dplyr)
library(tictoc)

#' subsetLandmask
#' @description get a regional subset of the landmask 
subsetLandmask <- function(landmask, shapes) {

# arguments
# landmask = global landmask 
# shapes   = shapefile to define the bounding box 

     #     # get new projection
     #     newProj  <- st_crs(shapes)$epsg
     #     
     #     # get the region as lat-long
     #     wgs84  <- 4326 # EPSG for WGS84
     #     buffer <- 1e5  # 100 km buffer
     #     region <- st_as_sfc(st_bbox(shapes)) %>% st_buffer(buffer) %>% st_transform(wgs84)
     #     
     #     # identify cases where the region is split across the dateline
     #     bbox        <- st_bbox(region)
     #     regionSplit <- as.logical(bbox[1]*bbox[3] < 0)
     #     
     #     # get the landmasses for the split region
     #     if(regionSplit){
     #     
     #      # region 1: west of the dateline
     #      bbox       <- st_bbox(region)
     #      bbox[1]    <- bbox[3]  # maximum is western edge if one of the longitudes is negative
     #      bbox[3]    <- 180      # the eastern edge
     #      westRegion <- st_as_sfc(bbox)
     #      landmass_1 <- st_intersection(landmask, westRegion)
     #     
     #      # region 2: east of the dateline
     #      bbox       <- st_bbox(region)
     #      bbox[3]    <- bbox[1]+360    # the eastern edge
     #      bbox[1]    <- 180            # the western edge
     #      eastRegion <- st_as_sfc(bbox)
     #     
     #      # get the separate landmasses
     #      landmass_1 <- st_intersection(landmask, westRegion)
     #      landmass_2 <- st_intersection(landmask, eastRegion)
     #     
     #     
     #     
     #     
     #     
     #     
     #     # ensure longitudes are 0-360
     #     if(regionSplit){
     #      print("fixing longitudes")
     #      temp <- bbox[1]+360          # get east longitude [0-360]
     #      bbox[1] <- bbox[3] - 30      # switch west with east
     #      bbox[3] <- temp    + 10      # put correct east
     #      region  <- st_as_sfc(bbox)   # new region
     #      print(region)
     #     }  # if the special case where the region is split across the dateline
     #     
     #     
     #     
     #     
     #     
     #     
     #     
     #     # get extent
     #     #  -- NSIDC EASE GRID equal area Northern Hemisphere
     #     if(newProj == 3408){
     #      cExtent <- c(xmin=-180, xmax=190, ymin=45, ymax=90)
     #     # -- Everything else (includes NSIDC EASE GRID global and Europe equal area
     #     } else {
     #      cExtent <- c(xmin=-180, xmax=190, ymin=-80, ymax=80)
     #     }
     #     
     #     # crop landmass
     #     # NOTE: This is done in lat-lon coordinated before re-projecting
     #     tic("crop landmask to the valid limits of the projection")
     #     landmass <- st_crop(landmask, cExtent)
     #     toc()  # print timing
     #     
     #     # transform landmass
     #     tic("reproject landmass to the desired projection")
     #     landmass <- st_transform(landmass, newProj)
     #     toc()  # print timing
     #     
     #     # get the regional bounding box
     #     buffer <- 1e5  # 100 km buffer
     #     region <- st_as_sfc(st_bbox(shapes)) %>% st_buffer(buffer)
     #     
     #     # get the regional subset
     #     # NOTE: only subset the landmask of a valid extent
     #     tic("get the spatial subset within the regional bounding box")
     #     landmass <- st_intersection(landmass, region)
     #     toc()  # print timing
     #     
     #     # convert MULTIPOLYGONS to POLYGONS
     #     landmass <- st_cast(landmass, "MULTIPOLYGON") %>% st_cast("POLYGON")
     #     
     #     # compute the polygon area
     #     landmass <- cbind(area=st_area(landmass), landmass)
     #     
     #     tic("sort the polygon area (largest to smallest)")
     #     landmass <- landmass[order(-landmass$area),]
     #     toc()  # print timing
     #     
     #     # define the feature ID
     #     row.names(landmass) <- NULL  # reset to 1,2,3,...,n
     #     landmass$FID <- rownames(landmass)
     #     
     #     # remove all columns EXCEPT for the feature ID and area
     #     landmass <- landmass[ , c("FID", "area")]

# end of function
return(landmass)
}
