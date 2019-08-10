library(sf)
library(dplyr)
library(tictoc)

#' getRegionLandmasses
#' @description Get a subset of landmasses for the region
getRegionLandmasses <- function(landmassGlobal, boundBox, epsgProj, buffer) {

# arguments
# landmassGlobal = shapfile of global landmasses
# boundBox       = lat/lon bounding box
# epsgProj       = desired EPSG proj
# buffer         = buffer (in degrees)

# get area tolerance
areaThreshold <- set_units(25e6, m^2)   # 25 km2

# define EPSG for WGS84
wgs84_proj <- 4326

# -----
# get regional subset within 1 deg of the input shapefile...
# ----------------------------------------------------------

# get regional landmask
# NOTE: Use lat-lon coordinates
tic("get regional landmask")
mapExtent      <- st_as_sfc(boundBox) %>% st_buffer(buffer)
landmassRegion <- st_intersection(landmassGlobal, mapExtent) %>% st_transform(epsgProj)
landmassDesire <- subset(landmassRegion, st_area(landmassRegion) > areaThreshold)
landmassOrig   <- subset(landmassDesire, !is.na(landmassDesire$OBJECTID))
toc()  # print timing

# -----
# special case east Russia: get polygons east of 180...
# -----------------------------------------------------

tic("get the subset of polygons east of the dateline")
if(boundBox[3] > 180){

 # define a bounding box for eastern Russia in the desired projection
 wantCoords <- c(180, 200, 45, 90)  # lon1, lon2, lat1, lat2
 eastRussia <- st_as_sfc(as(raster::extent(wantCoords), "SpatialPolygons"))
 eastExtent <- eastRussia %>% st_set_crs(wgs84_proj) %>% st_transform(epsgProj)

 # get the polygons east of the dateline
 extraPoly    <- subset(landmassDesire, is.na(landmassDesire$OBJECTID))
 extra180     <- st_intersection(extraPoly, eastExtent)
 extra180$FID <- rownames(extra180)

 # merge polygons east of the dateline
 landmass <- rbind(extra180, landmassOrig)

# standard case
} else {
 landmass <- landmassOrig
}  # special case of eastern Russia

# print timing
toc()

# -----
# clean up... 
# -----------

tic("clean up landmasses")

# ensure that all landmasses are polygons (shouldn't be needed, but just to make sure)
landmass <- landmass %>% group_by(OBJECTID) %>% summarize(do_union = FALSE) %>% st_cast("MULTIPOLYGON")
landmass <- landmass %>% group_by(OBJECTID) %>% summarize(do_union = FALSE) %>% st_cast("POLYGON")

# compute the polygon area
landmass <- cbind(area=st_area(landmass), landmass)
landmass <- landmass[order(-landmass$area),]

# define the feature ID
row.names(landmass) <- NULL  # reset to 1,2,3,...,n
landmass$FID <- rownames(landmass)

# remove all columns EXCEPT for the feature ID and area
regionLandmasses <- landmass[ , c("FID", "area")]

# print timing
toc()

return(regionLandmasses)
}
