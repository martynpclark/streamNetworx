library(sf)
library(dplyr)
library(tictoc)
source("extractPoint.R")
source("identifyLinkage.R")

#' splitCoastline
#' @description split coastline where rivers meet the ocean
splitCoastline <- function(outlets, lCoast, pCoast, fPath, ix0, id) {

# arguments
# outlets    = bottom-most point on dangling reaches
# lCoast     = coastline (LINESTRING)
# pCoast     = points on coastline (MULTIPOINT)
# fPath      = file path for temporary output
# ix0        = index used to create segId
# id         = id of the landmass

# logical definitions
yes <- 1
no  <- 0

# define the desire for verbose timing information
desireVerboseTiming <- no

# define the desire for temporary output files
desireTempOutput <- no

# define temporary output files
tempOutput_shp3  <- paste(fPath, "connectingPath.shp", sep="")
tempOutput_shp4  <- paste(fPath, "breakCoastPoints.shp", sep="")
tempOutput_shp5  <- paste(fPath, "splitCoastline.shp", sep="")
tempOutput_test1 <- paste(fPath, "test1.shp", sep="")
tempOutput_test2 <- paste(fPath, "test2.shp", sep="")

# initialize the start index
startIndex <- ix0
firstIter  <- yes

# ---------------------------------------------------------------------------
# ---------------------------------------------------------------------------
# ---------------------------------------------------------------------------

# -----
# * split the coastline where rivers drain to the coast...
# --------------------------------------------------------

# loop through features within a landmass
for (feature in 1:length(lCoast$FID)){

 # timing for features
 info <- paste("splitting feature", feature, "of length", floor(st_length(lCoast[feature,])), sep=" ")
 if(desireVerboseTiming == yes) tic(info)

 # get the logical vector defining the outlets closest to the current coastline
 isDesired <- outlets$coastId == lCoast$coastId[feature]
 if(sum(isDesired) > 0){ # if outlets intersect the coastal feature

  info <- "restrict attention to outlets that are close to the coast"
  if(desireVerboseTiming == yes) tic(info)
  closeTol  <- set_units(1000, m)   # 1000 m
  isCoastal <- st_distance(subset(outlets,isDesired), lCoast[feature,]) < closeTol
  isDesired[isDesired] <- isCoastal  # update desired outlets
  outlets$isCoastal[isDesired] = 1   # define coastal outlets
  subsetOutlets <- subset(outlets,isDesired)
  if(desireVerboseTiming == yes) toc()

  info <- "get artificial path connecting the dangling reaches to the coast"
  if(desireVerboseTiming == yes) tic(info)
  connectingPath <- st_nearest_points(subsetOutlets, pCoast[feature,])
  connectingPath <- st_sf(geometry=connectingPath)  # convert to a spatial data frame
  connectingPath <- cbind(COMID=subsetOutlets$COMID, connectingPath)
  if(desireTempOutput == yes)  write_sf(connectingPath, tempOutput_shp3)
  if(desireVerboseTiming == yes) toc()

  info <- "get the break points on the coastline"
  if(desireVerboseTiming == yes) tic(info)
  breakCoast <- extractPoint(connectingPath %>% select(COMID), c(1))  # get the last point in the connecting path
  if(desireTempOutput == yes)  write_sf(breakCoast, tempOutput_shp4)
  if(desireVerboseTiming == yes) toc()

  info <- "separate the coastline into inter-basin segments"
  if(desireVerboseTiming == yes) tic(info)
  coastSplit <- st_collection_extract(st_split(lCoast$geometry[feature], breakCoast$geometry), "LINESTRING")
  coastSplit <- st_sf(geometry=coastSplit)                    # convert to a spatial data frame
  if(desireVerboseTiming == yes) toc()

  # add some unique Ids
  nSplits    <- length(coastSplit$geometry)
  unique_ids <- id + seq(startIndex, startIndex+nSplits-1, 1)     # define a unique segment ID
  coastSplit <- cbind(segId=as.integer(unique_ids), coastSplit)   # add segment IDs to the data frame
  startIndex <- startIndex + nSplits

  info <- "get the first and last point of each coastline segment"
  if(desireVerboseTiming == yes) tic(info)
  coastSeg0 <- extractPoint(coastSplit %>% select(segId), c(0)) %>% select(segId) # get the first point in each coastline
  coastSeg1 <- extractPoint(coastSplit %>% select(segId), c(1)) %>% select(segId) # get the last point in each coastline
  #if(desireTempOutput == yes)  write_sf(coastSeg0, tempOutput_test1)
  #if(desireTempOutput == yes)  write_sf(coastSeg1, tempOutput_test2)
  if(desireVerboseTiming == yes) toc()

  info <- "get the spatial linkage along the coastline"
  if(desireVerboseTiming == yes) tic(info)
  # NOTE: This is identifying the ids of coastSeg1 that connect to coastSeg0
  coastSplit$FID     <- rep(-9999L,length(coastSplit$segId))
  coastSplit$coastId <- rep(lCoast$coastId[feature],length(coastSplit$segId))
  coastSplit$toCoast <- as.integer(identifyLinkage(coastSeg0, coastSeg1))
  if(desireTempOutput == yes)  write_sf(coastSplit, tempOutput_shp5)
  if(desireVerboseTiming == yes) toc()

 # no outlets intersect the coastal segment
 } else {

  # have the entire coastline segment as the coastal split
  coastSplit <- cbind(segId=startIndex+id, toCoast=-9999L, lCoast[feature,])
  startIndex <- startIndex+1L

 } # no outlets intersect the coastal segment

 # concatenate the coastal splits
 if(firstIter==yes) coastConnect <- coastSplit
 if(firstIter==no)  coastConnect <- rbind(coastConnect, coastSplit)

 # re-initialize the update flag
 firstIter=no

 if(desireVerboseTiming == yes) toc()  # print timing for features
 #stop("coastLoop")
 #break

} # loop through features within a landmass

return(coastConnect)
}
