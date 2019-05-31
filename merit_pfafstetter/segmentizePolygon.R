library(sf)
library(dplyr)
library(units)
library(lwgeom)
library(tictoc)
library(data.table)
source("lonlat2UTM.R")
source("extractPoint.R")
source("disaggLandmask.R")
source("getRegionLandmasses.R")
source("splitCoastline.R")
source("mergeCoastline.R")
source("orderCoastline.R")

source("identifyLinkage.R")

# logical definitions
yes <- 1
no  <- 0

# define EPSG for WGS84
wgs84_proj <- 4326 

# get area tolerance
areaThreshold <- set_units(25e6, m^2)   # 25 km2

# define paths 
merit_path  <- "/Users/mac414/geospatial_data/MERIT-hydro/"
output_path <- paste(merit_path, "pfafstetter/", sep="")

# define the temporary output shapefiles
tempOutput_shp0  <- paste(output_path, "landmass.shp", sep="")
tempOutput_shp1  <- paste(output_path, "dangling.shp", sep="")
tempOutput_shp2  <- paste(output_path, "danglingPoints.shp", sep="")
tempOutput_shp3  <- paste(output_path, "connectingPath.shp", sep="")
tempOutput_shp4  <- paste(output_path, "breakCoastPoints.shp", sep="")
tempOutput_shp5  <- paste(output_path, "splitCoastline.shp", sep="")
tempOutput_test1 <- paste(output_path, "test1.shp", sep="")
tempOutput_test2 <- paste(output_path, "test2.shp", sep="")
tempOutput_test3 <- paste(output_path, "test3.shp", sep="")
tempOutput_test4 <- paste(output_path, "test4.shp", sep="")

# define land mask
landmaskNames <- data.table(landmask_shp     = paste(merit_path, "landmask/all_land_dissolve_fix.shp", sep=""),
                            landPolygons_shp = paste(merit_path, "landmask/all_land_separated.shp", sep=""))

# disaggregate the landmask into separate polygons
landmassGlobal <- disaggLandmask(landmaskNames)

#########################
# loop through regions...
#########################
for (region in 35:99){

 # define the output shapefiles
 testRiver_shp   <- paste(output_path, "testRiver",        region, ".shp", sep="")
 outputRiver_shp <- paste(output_path, "riverConnections", region, ".shp", sep="")
 outputCoast_shp <- paste(output_path, "coastConnections", region, ".shp", sep="")
 
 # -----
 # * read regional shapefiles...
 # -----------------------------

 # define projection
 proj <- switch(as.character(floor(region/10)), 
                "2"=3035,  # Europe:          Single CRS for all Europe (equal area)
                "3"=3408,  # northern Russia: NSIDC EASE GRID equal area Northern Hemisphere
                "8"=3408,  # northern Canada: NSIDC EASE GRID equal area Northern Hemisphere
                 6933)     # default:         NSIDC EASE GRID global (not valid north of 84 deg N)

 # define region
 river_id      <- paste("riv_pfaf", region, sep="_")
 hillslope_id  <- paste("hillslope", region, sep="_")

 # define the rivers
 river_shp     <- paste(merit_path, "pfaf_level_02/", river_id, "_MERIT_Hydro_v07_Basins_v01_bugfix1.shp", sep="")

 # define coastal hillslopes
 hillslope_shp <- paste(merit_path, "coastal_hillslopes/", hillslope_id, "_clean.shp", sep="")

 # check that the file exists 
 if (!file.exists(river_shp)) next

 # read river shape file
 tic("reading rivers")
 rivers <- read_sf(river_shp)
 toc()  # print timing
 
 # read coastal hillslope shape file
 tic("reading coastal hillslopes")
 hillslope <- read_sf(hillslope_shp)
 toc()  # print timing

 # -----
 # * get the regional landmass... 
 # ------------------------------

 # define land mask
 landmaskNames <- cbind(landmaskNames, 
                  data.table(regionLandPoly_shp    = paste(merit_path, "landmask/all_land_", region, ".shp", sep=""),
                             regionCoastline_shp   = paste(merit_path, "landmask/coastline_", region, ".shp", sep=""),
                             regionCoastPoints_shp = paste(merit_path, "landmask/coastlinePoints_", region, ".shp", sep="")))

 # get regional landmasses
 regionLandmasses <- getRegionLandmasses(landmassGlobal, st_bbox(rivers), proj, landmaskNames$regionLandPoly_shp)

 # convert the regional landmasses to a LINESTRING
 landTemp  <- regionLandmasses %>% group_by(FID) %>% summarize(do_union = FALSE) %>% st_cast("POLYGON")
 coastTemp <- landTemp         %>% group_by(FID) %>% summarize(do_union = FALSE) %>% st_cast("MULTILINESTRING")
 coastline <- coastTemp        %>% group_by(FID) %>% summarize(do_union = FALSE) %>% st_cast("LINESTRING")
 coastline <- cbind(coastId=rownames(coastline), coastline)
 write_sf(coastline, landmaskNames$regionCoastline_shp)
 
 # convert the coastline to multiple points
 coastpoints <- coastline %>% st_cast("MULTIPOINT")
 write_sf(coastpoints, landmaskNames$regionCoastPoints_shp)
 
 #stop("testing")

 # ---------------------------------------------------------------------------------------------------------
 # ---------------------------------------------------------------------------------------------------------
 # ---------------------------------------------------------------------------------------------------------
 # ---------------------------------------------------------------------------------------------------------
 # ---------------------------------------------------------------------------------------------------------
 
 # -----
 # * intersect the rivers with the regional landmasses...
 # ------------------------------------------------------

 # -----
 # * get subsets for regional landmasses...
 # ----------------------------------------
 
 # transform coordinates
 tic("transforming coordinates")
 rivers    <- st_transform(rivers, proj)
 hillslope <- st_transform(hillslope, proj)
 toc()  # print timing

 # define the desire for temporary output files
 desireTempOutput <- no
 
 # define the desire for verbose timing information
 desireVerboseTiming <- no
 
 tic("get the subset of dangling reaches")
 dangling <- subset(rivers, NextDownID==0) %>% st_transform(proj)
 if(desireTempOutput == yes) write_sf(dangling, tempOutput_shp1)
 toc()  # print timing
 
 tic("get the outlet of each independent basin")
 outlets <- extractPoint(dangling %>% select(COMID), c(0))  # get the first point of the dangling reaches
 if(desireTempOutput == yes) write_sf(outlets, tempOutput_shp2)
 toc()  # print timing

 tic("get the nearest coastline to each outlet")
 nearestCoastline <- st_nearest_feature(outlets, coastline)
 toc()  # print timing

 # add the landmass ID and the coastal Id
 outlet_FID       <- coastline$FID[nearestCoastline] 
 outlet_coastId   <- coastline$coastId[nearestCoastline]
 outlet_isCoastal <- rep(0L, length(outlets$COMID))
 outlets <- cbind(FID=outlet_FID, coastId=outlet_coastId, isCoastal=outlet_isCoastal, outlets)

 # check that there is enough room for the ID in a 32-bit integer
 nOutlets  <- length(outlets$COMID)
 nLandmass <- sum(regionLandmasses$area > areaThreshold)

 # get the multiplier for the continent ID
 idMultOutlet   <- 10L^(nchar(nOutlets))
 idMultLandmass <- 10L^(nchar(nLandmass)) * idMultOutlet

 # check that we have not exceeded the carrying capacity of an integer
 intCheck <- region*idMultLandmass + nLandmass*idMultOutlet + nOutlets
 if(intCheck > .Machine$integer.max) stop("insufficient space for segment ID")

 # initialize the first iteration of the loop
 firstIter  <- yes
 startIndex <- 1L

 # ---------------------------------------------------------------------------------------------------------
 # ---------------------------------------------------------------------------------------------------------
 # ---------------------------------------------------------------------------------------------------------
 # ---------------------------------------------------------------------------------------------------------
 # ---------------------------------------------------------------------------------------------------------
 
 # loop through the landmasses
 for (id in 1:length(regionLandmasses$FID)){
 
  # check that the landmass area is greater than the threshold for defining the river network
  if(regionLandmasses$area[id] < areaThreshold) next

  # get a unique id for the landmass
  idLandmass <- as.integer(region*idMultLandmass) + as.integer(id*idMultOutlet)
 
  # define the timing for the loop
  tic(paste("processing landmass", idLandmass, "of area", floor(regionLandmasses$area[id]), sep=" "))
 
  tic(paste("get an isolated landmass", id, sep=" "))
  landmass <- subset(regionLandmasses, FID==as.character(id))
  if(desireTempOutput == yes)  write_sf(landmass, tempOutput_shp0)

  # get the coastline for the landmass
  lCoast <- subset(coastline, FID==as.character(id))
  pCoast <- subset(coastpoints, FID==as.character(id))
  toc()  # get an isolated landmass

  # --------------------------------------------------------------------------------------------------------
  # --------------------------------------------------------------------------------------------------------
  # --------------------------------------------------------------------------------------------------------
  # --------------------------------------------------------------------------------------------------------
  # --------------------------------------------------------------------------------------------------------

  tic("split coastline features where each river reaches the coast")
  coastSplit <- splitCoastline(outlets, lCoast, pCoast, output_path, startIndex, idLandmass)
  coastSplit$FID <- rep(id, length(coastSplit$FID))
  write_sf(coastSplit, tempOutput_test1)
  toc()
  #stop("split")

  tic("connect disaggregated coastline segments")
  startIndex <- as.integer(max(coastSplit$segId)-idLandmass) + 1L
  coastMerge <- mergeCoastline(coastSplit, lCoast, startIndex, idLandmass) 
  write_sf(coastMerge, tempOutput_test2)
  toc()
  #stop("merge")

  tic("order coastline segments")
  coastOrder <- orderCoastline(coastMerge)
  write_sf(coastOrder, tempOutput_test3)
  toc()
  stop("order")

  #coastTemp <- coastOrder %>% group_by(FID) %>% summarize(do_union = FALSE) %>% st_cast("POLYGON")

  # print timing for all features within a landmass
  toc()
  stop("landmass loop")
 
 } # looping through landmasses
 
 # merge with the outlets
 st_geometry(riverConnect) <- NULL # remove geometry (retain only the data frame)
 riverConnect <- left_join(outlets[ , c("COMID")], riverConnect[ , c("COMID", "toCoast")], by="COMID")
 
 # write regional shapefiles
 write_sf(riverConnect, outputRiver_shp)
 write_sf(coastConnect, outputCoast_shp)

 stop("region loop")

} # looping through regions
