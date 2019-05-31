library(sf)
library(dplyr)
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

# initialize the start index
startIndex <- ix0

# initialize coastConnect
coastConnect        <- coastSplit
coastConnect$index  <- as.integer(seq(1L,length(coastConnect$segId),1L))

# order coastline segments w.r.t. length
lCoast$length <- st_length(lCoast)
lCoast$index  <- seq(1,length(lCoast$coastId),1)
coastOrder    <- st_drop_geometry(lCoast[order(lCoast$length),])

# extract first and last points in the line
point0 <- extractPoint(lCoast %>% select(coastId), c(0))  # get the first point
point1 <- extractPoint(lCoast %>% select(coastId), c(1))  # get the last point

# loop through features within a landmass
for (iFeature in 1:length(lCoast$FID)){

 # timing for features
 info <- paste("merging feature", iFeature, "of length", floor(st_length(lCoast[iFeature,])), sep=" ")
 if(desireVerboseTiming == yes) tic(info)

 # get the ranked index
 jFeature <- coastOrder$index[iFeature]

 # get the set of nearest segments
 ixValid   <- subset(lCoast$index, lCoast$index != jFeature) # ignore segment jFeature
 ixNearest <- ixValid[st_nearest_feature(point0[jFeature,], lCoast[ixValid,])]
 coastMask <- subset(coastConnect$index, coastConnect$coastId == lCoast$coastId[ixNearest])

 # split the nearest segment in the segment set
 iyNearest <- st_nearest_feature(point0[jFeature,], coastConnect[coastMask,])
 line      <- coastConnect[coastMask[iyNearest],]   # the nearest segment in the segment set
 point     <- point0[jFeature,]                     # the staring point in the desired feature
 if(!st_intersects(line, point, sparse=FALSE)) next # check that the point intersects the line
 split     <- st_collection_extract(st_split(line$geometry,point$geometry), "LINESTRING")     # new line string
 split     <- st_sf(geometry=split)                 # convert to a spatial data frame
 if(length(rownames(split)) != 2) stop("expect split=2")

 # get the mask for the new segments
 insertMask <- subset(coastConnect$index, coastConnect$coastId == lCoast$coastId[jFeature])

 # update the network topology
 #   to coast
 #        <-- ----------- ----------- -----------
 #            1st segment new segment 2nd segment

 # get the new line segments
 ixLine   <- coastMask[iyNearest]
 newLine1 <- st_sf(cbind(st_drop_geometry(coastConnect[ixLine,]), split[1,]$geometry))
 newLine2 <- st_sf(cbind(st_drop_geometry(coastConnect[ixLine,]), split[2,]$geometry))

 # check if there are multiple segments to merge
 if(length(insertMask) > 1){

  # identify the first segment in the new section
  pTest   <- extractPoint(newLine1 %>% select(segId), c(1)) # last point in the 1st newline
  pStart  <- extractPoint(coastConnect[insertMask,] %>% select(segId), c(0))  # vector of starting points
  isFirst <- st_intersects(pStart, pTest, sparse=FALSE)
  if(sum(isFirst) != 1) stop(" cannot identify the first segment in the new section")
  ixFirst <- which(isFirst)

  # identify the last segment in the new section
  pTest   <- extractPoint(newLine2 %>% select(segId), c(0)) # first point in the 2nd newline
  pEnd    <- extractPoint(coastConnect[insertMask,] %>% select(segId), c(1))  # vector of ending points
  isLast  <- st_intersects(pEnd, pTest, sparse=FALSE)
  if(sum(isLast) != 1) stop(" cannot identify the last segment in the new section")
  ixLast  <- which(isLast)

 # a single segment to merge
 } else {
  ixFirst <- 1
  ixLast  <- 1
 } # if multiple segments to merge

 # get the new line segment: connect the start of the segment to newLine1
 coastConnect$toCoast[insertMask[ixFirst]] <- newLine1$segId
 newSegment <- coastConnect$segId[insertMask[ixFirst]]

 # get the 2nd line segment: connect newLine2 to the end of the new segmeent
 newLine2$segId   <- id + as.integer(startIndex)
 newLine2$toCoast <- coastConnect$segId[insertMask[ixLast]]
 startIndex       <- startIndex+1L

 # remove original rows
 removeRows   <- coastConnect$segId == newLine1$segId
 coastConnect <- subset(coastConnect, !removeRows)

 # merge line segments
 coastConnect        <- rbind(coastConnect, newLine1, newLine2)
 coastConnect$index  <- as.integer(seq(1L,length(coastConnect$segId),1L))

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
  jxMatch    <- which(coastConnect$segId[ixMatch] != newSegment & coastConnect$segId[ixMatch] != newLine2$segId)
  kxMatch    <- ixMatch[jxMatch]
  if(length(jxMatch) != 1) stop("no unique target segment")

  # update linkage
  coastConnect$toCoast[kxMatch] <- newLine2$segId

 } # if there is a match

 # check
 #if(iFeature==94) break

 # print timing for features
 if(desireVerboseTiming == yes) toc()

} # loop through features within a landmass

return(coastConnect)
}
