library(sf)
library(dplyr)
library(units)
library(tictoc)
source("extractPoint.R")
source("identifyLinkage.R")

#' mergeCoastline
#' @description connect coastline where there are self intersections
mergeCoastline <- function(coastSplit, lCoast, ix0, id) {

# arguments
# outlets    = bottom-most point on dangling reaches
# lCoast     = coastline (LINESTRING)
# ix0        = index used to create segId

# logical definitions
yes <- 1
no  <- 0

# define the desire for verbose timing information
desireVerboseTiming <- no

# check that there are actually segments to merge
if(length(lCoast$FID) == 1) return(coastSplit)

# define the distance threshold
distClose  <- set_units(1, m)   # 1 m

# initialize the start index
startIndex <- ix0

# initialize coastConnect
coastConnect        <- coastSplit
coastConnect$index  <- as.integer(seq(1L,length(coastConnect$segId),1L))

# order coastline segments w.r.t. length
lCoast$isValid <- rep(TRUE,length(lCoast$coastId))
lCoast$length  <- st_length(lCoast)
lCoast$index   <- seq(1,length(lCoast$coastId),1)
coastOrder     <- st_drop_geometry(lCoast[order(lCoast$length),])

# extract first and last points in the line
point0 <- extractPoint(lCoast %>% select(coastId), c(0))  # get the first point
point1 <- extractPoint(lCoast %>% select(coastId), c(1))  # get the last point

# loop through features within a landmass
# NOTE: -1 because do not merge longest coastline
for (iFeature in 1:(length(lCoast$FID)-1)){

 # timing for features
 info <- paste("merging feature", iFeature, "of length", floor(st_length(lCoast[iFeature,])), sep=" ")
 if(desireVerboseTiming == yes) tic(info)

 # get the ranked index
 jFeature <- coastOrder$index[iFeature]

 # get the starting points for the set of nearest segments (a given coastId)
 ixValid   <- subset(lCoast$index, lCoast$index != jFeature) # ignore segment jFeature
 ixNearest <- ixValid[st_nearest_feature(point0[jFeature,], lCoast[ixValid,])]
 coastMask <- subset(coastConnect$index, coastConnect$coastId == lCoast$coastId[ixNearest])

 # get the nearest coastal segment in the segment set
 ixClose   <- which(st_distance(point0[jFeature,], coastConnect[coastMask,]) < distClose)

 # remove isolated segments
 if(length(ixClose) == 0){
  lCoast$isValid[jFeature] <- FALSE
  next # don't merge isolated segments
 } # if removing isolated segments

 # there can be two connected segments if the self-interection is located at a segment junction:
 #  -- identify the segment where the end point is next to the intersection
 if(length(ixClose) > 1){
  coastPoint <- extractPoint(coastConnect[coastMask[ixClose],] %>% select(coastId), c(1))  # get the last point
  iyClose    <- which(st_distance(point0[jFeature,], coastPoint) < distClose)
  if(length(iyClose) !=1) stop("cannot find the unique segment")
  iyNearest <- ixClose[iyClose]
 
 # standard case of one segment (self intersection in the middle of a segment)
 } else { # if >1 close segments
  iyNearest <- ixClose
 }        # if just one close segments

 # extract the point and the line
 line      <- coastConnect[coastMask[iyNearest],]   # the closest segment in the segment set
 point     <- point0[jFeature,]                     # the staring point in the desired feature

 # split the nearest segment in the segment set
 if(!st_intersects(line, point, sparse=FALSE)) next # check that the point intersects the line
 split     <- st_collection_extract(st_split(line$geometry,point$geometry), "LINESTRING")     # new line string
 split     <- st_sf(geometry=split)                 # convert to a spatial data frame
 nSplit    <- length(rownames(split))               # number of splits
 if(nSplit > 2) stop("expect split<=2")             # check (NOTE: nSplit=1 if the new segment is at the start/end of the orig segment)

 # get the mask for the new segments
 insertMask <- subset(coastConnect$index, coastConnect$coastId == lCoast$coastId[jFeature])
 ixLine     <- coastMask[iyNearest]  # index of the original segment

 # update the network topology
 #   to coast
 #        <-- ----------- ----------- -----------
 #            1st segment new segment 2nd segment

 # get the 1st newLine segment
 newLine1 <- st_sf(cbind(st_drop_geometry(coastConnect[ixLine,]), split[1,]$geometry))
 if(length(insertMask) > 1){  # multiple segments to merge
  pTest   <- extractPoint(newLine1 %>% select(segId), c(1)) # last point in the 1st newline
  pStart  <- extractPoint(coastConnect[insertMask,] %>% select(segId), c(0))  # vector of starting points
  isFirst <- st_distance(pTest, pStart) < distClose
  if(sum(isFirst) != 1) stop(" cannot identify the first segment in the new section")
  ixFirst <- which(isFirst)
 } else { # a single segment to merge
  ixFirst <- 1
 } # if multiple segments to merge

 # get the new line segment: connect the start of the segment to newLine1
 coastConnect$toCoast[insertMask[ixFirst]] <- newLine1$segId
 newSegment <- coastConnect$segId[insertMask[ixFirst]]

 # check if there are two splits
 if(nSplit==2){ # nSplit=1 if the new segment is at the start/end of the orig segment

  # get the 2nd newLine segment
  newLine2 <- st_sf(cbind(st_drop_geometry(coastConnect[ixLine,]), split[2,]$geometry))
  if(length(insertMask) > 1){
   pTest   <- extractPoint(newLine2 %>% select(segId), c(0)) # first point in the 2nd newline
   pEnd    <- extractPoint(coastConnect[insertMask,] %>% select(segId), c(1))  # vector of ending points
   isLast  <- st_intersects(pEnd, pTest, sparse=FALSE)
   if(sum(isLast) != 1) stop(" cannot identify the last segment in the new section")
   ixLast  <- which(isLast)
  } else { # a single segment to merge
   ixLast  <- 1
  } # if multiple segments to merge

  # get the 2nd line segment: connect newLine2 to the end of the new segmeent
  newLine2$segId   <- id + as.integer(startIndex)
  newLine2$toCoast <- coastConnect$segId[insertMask[ixLast]]
  startIndex       <- startIndex+1L

  # merge line segments
  removeRows   <- coastConnect$segId == newLine1$segId
  coastConnect <- subset(coastConnect, !removeRows)
  coastConnect <- rbind(coastConnect, newLine1, newLine2)

  # update the coastConnect index
  coastConnect$index  <- as.integer(seq(1L,length(coastConnect$segId),1L))

  # save the ID for the second newLine
  newLine2id <- newLine2$segId

 # no need for any splitting if there is just one new line
 } else { # if(nSplit==2)
  newLine2id <--9999L
 } # nSplit=1

 # update the toCoast ID for the segment that connects to newLine2
 # |---------| |---------| |---------| |------------|
 # 1st segment new segment 2nd segment target segment
 # - before inserting new segment the target segment pointed to the first segment
 # - we need the target segment to point to the second segment

 # first, get the segments that point to the 1st segment (newLine1)
 #  (this will be both the new segment AND the target segment)
 ixMatch <- which(coastConnect$toCoast==newLine1$segId) 
 if(length(ixMatch)>1){  # must be >1 match because include the new segment and the second segment

  # identify the target segment
  jxMatch    <- which(coastConnect$segId[ixMatch] != newSegment & coastConnect$segId[ixMatch] != newLine2id)
  kxMatch    <- ixMatch[jxMatch]
  if(length(jxMatch) != 1) stop("no unique target segment")

  # update linkage
  if(nSplit==2){
   coastConnect$toCoast[kxMatch] <- newLine2id
  } else {
   pEnd    <- extractPoint(coastConnect[insertMask,] %>% select(segId), c(1))  # vector of ending points
   isLast  <- st_intersects(pEnd, coastConnect[kxMatch,], sparse=FALSE)
   if(sum(isLast) != 1) stop(" cannot identify the last segment in the new section")
   ixLast  <- which(isLast)
   coastConnect$toCoast[kxMatch] <- coastConnect$segId[insertMask[ixLast]]
  } # nSplit=1

 } # if there is a match

 # print timing for features
 if(desireVerboseTiming == yes) toc()

} # loop through features within a landmass

# restrict attention to valid coastline segments
isCoastValid  <- rep(TRUE,length(coastConnect$coastId))
for (iCoast in 1:(length(lCoast$FID))){
 if(!lCoast$isValid[iCoast]){
  ixRemove <- which(coastConnect$coastId == lCoast$coastId[iCoast])
  isCoastValid[ixRemove] <- FALSE
 } # if coastline is invalid
} # looping through coastline segments

# get the valid subset
coastConnect <- subset(coastConnect, isCoastValid)

return(coastConnect)
}
