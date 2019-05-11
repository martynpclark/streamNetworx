library(sf)
library(dplyr)
library(units)
library(lwgeom)
library(tictoc)
library(data.table)
source("extractPoint.R")
source("identifyLinkage.R")
source("getLandmaskRegion.R")

# logical definitions
yes <- 1
no  <- 0

# define projection
#proj <- 5070  # NOTE: 5070 is CONUS Albers. Need to change for other regions.
proj <- 3035  # NOTE: 3035 is Europe equal area. Need to change for other regions.
#proj <- 7722  # NOTE: 1121 is India. Need to change for other regions.
#proj <- 3408  # NOTE: 3408 is equal area Northern Hemisphere. Need to change for other regions.
#proj <- 102022  # NOTE: 102022 is Africa Albers equal area conic
#proj <- 6932  # NOTE: 6932 is the NSIDC EASE grid for the southern hemisphere 

# -----
# * define files...
# -----------------

# define paths 
merit_path  <- "/Users/mac414/geospatial_data/MERIT-hydro/"
output_path <- paste(merit_path, "pfafstetter/", sep="")

# define region
region        <- "21"    # 21 is southern Europe
#region        <- "57"    # 57 is NZ
river_id      <- paste("riv_pfaf", region, sep="_")
hillslope_id  <- paste("hillslope", region, sep="_")

# define the rivers
river_shp     <- paste(merit_path, "pfaf_level_02/", river_id, "_MERIT_Hydro_v07_Basins_v01_bugfix1.shp", sep="")

# define coastal hillslopes
hillslope_shp <- paste(merit_path, "coastal_hillslopes/", hillslope_id, "_clean.shp", sep="")

# define land mask
landmaskNames <- data.table(landmask_shp          = paste(merit_path, "landmask/all_land_dissolve_fix.shp", sep=""),
                            landPolygons_shp      = paste(merit_path, "landmask/all_land_separated.shp", sep=""),
                            regionLandPoly_shp    = paste(merit_path, "landmask/all_land_", region, ".shp", sep=""),
                            regionCoastline_shp   = paste(merit_path, "landmask/coastline_", region, ".shp", sep=""),
                            regionCoastPoints_shp = paste(merit_path, "landmask/coastlinePoints_", region, ".shp", sep=""))

# define the output shapefile
outputCoast_shp <- paste(output_path, "coastConnections.shp", sep="")
outputRiver_shp <- paste(output_path, "riverConnections.shp", sep="")

# -----
# * read files...
# ---------------

# read river shape file
tic("reading rivers")
rivers <- read_sf(river_shp) %>% st_transform(proj)
toc()  # print timing

# read coastal hillslope shape file
tic("reading coastal hillslopes")
hillslope <- read_sf(hillslope_shp) %>% st_transform(proj)
toc()  # print timing

# read the regional landmask
landmask <- getLandmaskRegion(landmaskNames, rivers)

# convert the landmask to a LINESTRING
coastline <- st_cast(landmask, "POLYGON") %>% st_cast("LINESTRING")
write_sf(coastline, landmaskNames$regionCoastline_shp)

# convert the coastline to multiple points
coastpoints <- st_cast(coastline, "MULTIPOINT")
write_sf(coastpoints, landmaskNames$regionCoastPoints_shp)

# -----
# * intersect the rivers with the landmask...
# -----------------------------------------------

# define the temporary output shapefiles
tempOutput_shp0  <- paste(output_path, "landmass.shp", sep="")
tempOutput_shp1  <- paste(output_path, "dangling.shp", sep="")
tempOutput_shp2  <- paste(output_path, "danglingPoints.shp", sep="")
tempOutput_shp3  <- paste(output_path, "connectingPath.shp", sep="")
tempOutput_shp4  <- paste(output_path, "breakCoastPoints.shp", sep="")
tempOutput_shp5  <- paste(output_path, "splitCoastline.shp", sep="")
tempOutput_test1 <- paste(output_path, "test1.shp", sep="")
tempOutput_test2 <- paste(output_path, "test2.shp", sep="")

# define the desire for temporary output files
desireTempOutput <- no

# define the desire for verbose timing information
desireVerboseTiming <- no

tic("get the subset of dangling reaches")
dangling <- subset(rivers, NextDownID==0) %>% st_transform(proj)
write_sf(dangling, tempOutput_shp1)
toc()  # print timing

tic("get the outlet of each independent basin")
outlets <- extractPoint(dangling %>% select(COMID), c(0))  # get the first point of the dangling reaches
write_sf(outlets, tempOutput_shp2)
toc()  # print timing

# get the multiplier for the continent ID
idMult <- 10L^(nchar(length(outlets$COMID))+1)

# initialize the first iteration of the loop
firstIter <- yes

# loop through the landmasses
for (id in 1:length(landmask$FID)){

 # check that the landmass area is greater than the threshold for defining the river network
 if(landmask$area[id] < 25000000) next # 25 km2

 # define the timing for the loop
 tic(paste("processing landmass", id, "of area", floor(landmask$area[id]), sep=" "))

 # get a unique id for the landmass
 idLandmass <- as.integer(id*idMult)

 info <- paste("get an isolated landmass", id, sep=" ")
 if(desireVerboseTiming == yes) tic(info)
 landmass <- subset(landmask, FID==as.character(id))
 if(desireTempOutput == yes)  write_sf(landmass, tempOutput_shp0)
 if(desireVerboseTiming == yes) toc()

 # get the coastline for the landmass
 lCoast <- subset(coastline, FID==as.character(id))
 pCoast <- subset(coastpoints, FID==as.character(id))

 info <- "get the basin outlets that drain to the coast"
 if(desireVerboseTiming == yes) tic(info)

 # get outlets close to the coastline
 # NOTE: this is faster than st_intersects
 closeTol      <- 1000   # m
 closeCoastal  <- st_is_within_distance(outlets, lCoast, closeTol)
 isValidPoint  <- lengths(closeCoastal) > 0  # first try (close to coast)
 if(sum(isValidPoint) == 0) next

 # get dangling reaches within the isolated landmass
 checkLandmass <- st_intersects(subset(dangling, isValidPoint), landmass)
 isValidPoint[isValidPoint] <- lengths(checkLandmass) > 0 # overwrite close points with intersections
 subsetOutlets <- subset(outlets, isValidPoint)
 if(desireVerboseTiming == yes) toc()
 if(sum(isValidPoint) == 0) next

 info <- "get artificial path connecting the dangling reaches to the coast"
 if(desireVerboseTiming == yes) tic(info)
 connectingPath <- st_nearest_points(subsetOutlets, pCoast)
 connectingPath <- st_sf(geometry=connectingPath)  # convert to a spatial data frame
 connectingPath <- cbind(COMID=subsetOutlets$COMID, connectingPath)
 if(desireTempOutput == yes)  write_sf(connectingPath, tempOutput_shp3)
 if(desireVerboseTiming == yes) toc()

 info <- "get the break points on the coastline"
 if(desireVerboseTiming == yes) tic(info)
 breakCoast <- extractPoint(connectingPath %>% select(COMID), c(1))  # get the last point in the connecting path
 if(desireVerboseTiming == yes) toc()

 info <- "separate the coastline into inter-basin segments"
 if(desireVerboseTiming == yes) tic(info)
 coastSplit <- st_collection_extract(st_split(lCoast$geometry, breakCoast$geometry), "LINESTRING")
 coastSplit <- st_sf(geometry=coastSplit)                    # convert to a spatial data frame
 unique_ids <- idLandmass + as.integer(rownames(coastSplit)) # define a unique segment ID
 coastSplit <- cbind(segId=unique_ids, coastSplit)           # add segment IDs to the data frame
 if(desireVerboseTiming == yes) toc()

 info <- "remove very long coastal segments"
 if(desireVerboseTiming == yes) tic(info)
 veryLong <- set_units(1e6, m)   # 1000 km
 coastSplit$length <- st_length(coastSplit)                  # add length of each segment
 coastSplit <- subset(coastSplit, coastSplit$length < veryLong) # remove segments > maxLength
 if(desireVerboseTiming == yes) toc()

 info <- "get the first and last point of each coastline segment"
 if(desireVerboseTiming == yes) tic(info)
 coastSeg0 <- extractPoint(coastSplit %>% select(segId), c(0)) %>% select(segId) # get the first point in each coastline segment
 coastSeg1 <- extractPoint(coastSplit %>% select(segId), c(1)) %>% select(segId) # get the last point in each coastline segment
 if(desireTempOutput == yes)  write_sf(coastSeg0, tempOutput_test1)
 if(desireTempOutput == yes)  write_sf(coastSeg1, tempOutput_test2)
 if(desireVerboseTiming == yes) toc()

 info <- "get the spatial linkage from rivers to the coastline"
 if(desireVerboseTiming == yes) tic(info)
 # NOTE: This is identifying the ids of coastSeg1 that connect to breakCoast
 breakCoast$toCoast <- identifyLinkage(breakCoast, coastSeg1)
 if(desireTempOutput == yes)  write_sf(breakCoast, tempOutput_shp4)
 if(desireVerboseTiming == yes) toc()

 info <- "get the spatial linkage along the coastline"
 if(desireVerboseTiming == yes) tic(info)
 # NOTE: This is identifying the ids of coastSeg1 that connect to coastSeg0
 coastSplit$toCoast <- identifyLinkage(coastSeg0, coastSeg1)
 if(desireTempOutput == yes)  write_sf(coastSplit, tempOutput_shp5)
 if(desireVerboseTiming == yes) toc()

 # concatenate the river connections
 if(firstIter==yes) riverConnect <- breakCoast
 if(firstIter==no)  riverConnect <- rbind(riverConnect, breakCoast)
 
 # concatenate the coastal splits
 if(firstIter==yes) coastConnect <- coastSplit
 if(firstIter==no)  coastConnect <- rbind(coastConnect, coastSplit)

 # re-initialize the update flag
 firstIter=no

 toc()  # print timing
 #stop("loop")

} # looping through landmasses

# merge with the outlets
st_geometry(riverConnect) <- NULL # remove geometry (retain only the data frame)
riverConnect <- left_join(outlets[ , c("COMID")], riverConnect[ , c("COMID", "toCoast")], by="COMID")

# write regional shapefiles
write_sf(riverConnect,        outputRiver_shp)
write_sf(coastConnect, outputCoast_shp)
