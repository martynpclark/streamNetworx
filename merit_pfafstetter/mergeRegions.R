library(sf)
library(dplyr)
library(units)
library(lwgeom)
library(tictoc)
library(data.table)
source("extractPoint.R")

# define paths 
merit_path <- "/Users/mac414/geospatial_data/MERIT-hydro/"
shape_path <- paste(merit_path, "pfafstetter/", sep="")

# define overlap codes
unique <- 0
match  <- 1
long   <- 2

# define missing integers
integerMissing <- -9999L

# define the maximum number of trials
maxTry <- 10

# define the distance tolerance
tolDist  <- set_units(1, m)         # 1 meter
longDist <- set_units(1000000, m)   # 1000 km

# define desired regions
europe <- c(21,22,23,24,25,27)

# define continent
continent <- europe

# *****
# * trim coastline in each region...
# **********************************

# loop through regions...
for (iShape in continent){

 # define the coast subset shapefile
 coastSubset_shp <- paste(shape_path, "coastConnectionsTrim", iShape, ".shp", sep="")
 if (file.exists(coastSubset_shp)) next   # NOTE: turn off processing

 # read the coast connection shapefile
 coastConnect_shp <- paste(shape_path, "coastConnections", iShape, ".shp", sep="")
 if (!file.exists(coastConnect_shp)) next
 coastConnect     <- read_sf(coastConnect_shp)
 nCoast           <- length(coastConnect$segId)
 print(coastConnect_shp)

 # read the river connection shapefile
 riverConnect_shp <- paste(shape_path, "riverConnections", iShape, ".shp", sep="")
 riverConnect     <- read_sf(riverConnect_shp)
 #print(riverConnect_shp)

 # convert the river connections to a data frame
 riverData  <- riverConnect %>% st_set_geometry(NULL)  # get the rivers as a data table
 riverData  <- cbind(region=rep(as.integer(iShape),length(riverData$COMID)), riverData) # add the region

 # merge the river connections with the coastal connections
 coastJoin  <- left_join(x=coastConnect, y=riverData, by=c("segId"="toCoast"))
 coastMerge <- coastJoin[!duplicated(coastJoin$segId),] # remove duplicates

 # replace NA with named integers
 coastMerge$COMID[is.na(coastMerge$COMID)] <- integerMissing
 coastMerge$COMID <- as.integer(coastMerge$COMID)

 # get the runs
 runs    <- rle(coastMerge$COMID)
 ixOrder <- order(-runs$lengths)  # get indices in reverse order of run length
 
 # identify the length of each segment
 segLength <- st_length(coastMerge)

 # remove long segments
 ixDesire <- rep(TRUE, nCoast)
 for (i in 1:10){  # just test the top ten runs
  i1     <- sum(runs$lengths[1:ixOrder[i]-1])+1
  i2     <- i1 + runs$lengths[ixOrder[i]]
  if(sum(st_length(coastMerge[i1:i2,])) > longDist) ixDesire[i1:i2] <- FALSE
 } # looping through run lengths

 # write subset
 write_sf(subset(coastMerge, ixDesire), coastSubset_shp)
 #stop("testing")

} # looping through regions

# *****
# * connect coastline across regions...
# *************************************

# loop through regions...
for (iShape in continent){

 # define the coastal shapefiles
 baseSubset_shp  <- paste(shape_path, "coastConnectionsTrim", iShape, ".shp", sep="")
 baseConnect_shp <- paste(shape_path, "coastConnections", iShape, ".shp", sep="")
 if (!file.exists(baseSubset_shp)) next
 if (file.exists(baseSubset_shp)) next   # NOTE: Turn off processing
 print(baseSubset_shp)
 print("*****")

 # read the coastal shapefiles
 baseSubset      <- read_sf(baseSubset_shp)
 baseConnect     <- read_sf(baseConnect_shp)

 # find the coastal segments at the head of the line
 tableHead <- left_join(x=baseSubset, y=baseSubset %>% st_set_geometry(NULL), by=c("segId"="toCoast"))
 ixHead    <- which(is.na(tableHead$segId.y))
 if(length(ixHead) == 0) next
 write_sf(baseSubset[ixHead,], paste("test/headLine",iShape,".shp",sep=""))

 # find the coastal segments at the tail of the line
 #tableTail <- left_join(x=baseSubset, y=baseSubset %>% st_set_geometry(NULL), by=c("toCoast"="segId"))
 #ixTail    <- which(is.na(tableTail$toCoast.y))
 #write_sf(baseSubset[ixTail,], paste("test/tailLine",iShape,".shp",sep=""))
 #stop("testing")

 # loop through overlapping regions
 for (jShape in continent){

  # skip the same region
  if(iShape==jShape) next

  # define the coastal shapefiles
  overSubset_shp  <- paste(shape_path, "coastConnectionsTrim", jShape, ".shp", sep="")
  overConnect_shp <- paste(shape_path, "coastConnections", jShape, ".shp", sep="")
  if (!file.exists(overSubset_shp)) next
  print(paste(iShape,overSubset_shp))
  
  # read the coastal shapefiles
  overSubset      <- read_sf(overSubset_shp)
  overConnect     <- read_sf(overConnect_shp)

  # *****
  # * get connections with the head segments...
  # *******************************************

  # loop through the different head segments
  for (iCheck in 1:length(ixHead)){

   # get the coastline at the head
   lineHead <- baseSubset[ixHead[iCheck],]
   if(length(lineHead$geometry) == 0) next

   # find intersections with the head in the full coastline
   ixMatch <- which(st_intersects(lineHead,overConnect, sparse=FALSE))
   write_sf(overConnect[ixMatch,], paste("test/connectOverlap",jShape,".shp",sep=""))
   if(length(ixMatch) == 0) next

   # find intersections with the head in the trim coastline
   iyMatch <- which(st_intersects(lineHead,overSubset, sparse=FALSE))

   # connection with the subset
   if(length(iyMatch) > 0){

    # split the line at the bottom of the tail segment
    pointTail <- extractPoint(overSubset[min(iyMatch),] %>% select(segId), c(0))
    splitLine <- st_collection_extract(st_split(lineHead$geometry, pointTail$geometry), "LINESTRING")
    splitLine <- st_sf(geometry=splitLine)

    # update the topology
    baseSubset[ixHead[iCheck],]      <- st_set_geometry(lineHead, splitLine$geometry[1])
    overSubset$toCoast[min(iyMatch)] <- lineHead$segId

   # gap between trimmed topologies
   } else {

    # get the overlapping segment
    pointHead  <- extractPoint(lineHead %>% select(segId), c(1))
    segOverlap <- st_difference(overConnect[min(ixMatch),], lineHead) %>% st_cast("LINESTRING")
    ixSegMatch <- which(st_touches(segOverlap,pointHead, sparse=FALSE))

    # create a missing object
    if(length(ixSegMatch) ==1){
     missTable  <- cbind(overConnect[min(ixMatch),] %>% st_set_geometry(NULL), region=NA, COMID=-9999L, uparea=-9999)
     missObject <- st_set_geometry(missTable, segOverlap$geometry[ixSegMatch])
     isTouching <- sum(st_touches(missObject,overSubset,sparse=FALSE)) > 0
     overSubset <- rbind(missObject, overSubset)               # insert missing segments     
     if(isTouching) overSubset$toCoast[1] <- lineHead$segId    # update connection
    } else {  # creating a missing object
     isTouching <- FALSE
    }

    # check if need to identify missing segments
    if(!isTouching){

     # identify missing segments
     i1 <- min(ixMatch)+1
     i2 <- integerMissing
     for (jMatch in i1:(i1+maxTry)){
      if(sum(st_touches(overConnect[jMatch,], overSubset, sparse=FALSE)) > 0){
       i2 <- jMatch
       break
      } # if found an intersection
     } # looping through trial values
     if(i2 == integerMissing) next # could not find intersection
     if(i2<i1) stop("backward intersection")
     print(paste("i1, i2: ", overConnect$segId[i1], overConnect$segId[i2]))
     n <- (i2-i1)+1
  
     # update the topology
     newTable   <- cbind(overConnect[i1:i2,] %>% st_set_geometry(NULL), region=rep(NA,n), COMID=rep(-9999L,n), uparea=rep(-9999,n))
     newObject  <- st_set_geometry(newTable, overConnect$geometry[i1:i2])
     overSubset <- rbind(newObject, overSubset) # insert missing segments
     overSubset$toCoast[1] <- lineHead$segId    # update connection 
     write_sf(newObject, paste("test/newObject",jShape,".shp",sep=""))

    }  # if need to identify missing segments
    #stop("not in the trim")

   }  # gap between trimmed topologies

  }  # loop through matches

  # write overlapping regions
  write_sf(overSubset, overSubset_shp)

 } # looping through overlapping regions

 # write base regions
 write_sf(baseSubset, baseSubset_shp)
 #stop("testing")

} # looping through regions

# *****
# * merge coastline across regions...
# *************************************

# loop through regions...
for (iShape in continent){

 # read the coastal shapefiles
 coastalSubset_shp  <- paste(shape_path, "coastConnectionsTrim", iShape, ".shp", sep="")
 coastalSubset      <- read_sf(coastalSubset_shp)
 print(paste("merging",coastalSubset_shp))

 # concatenate the coastal segments
 if(iShape == continent[1]) coastConnect <- coastalSubset
 if(iShape != continent[1]) coastConnect <- rbind(coastConnect, coastalSubset)

}  # looping through shapefiles

# find the coastal segments at the tail of the line
tableTail <- left_join(x=coastConnect, y=coastConnect %>% st_set_geometry(NULL), by=c("toCoast"="segId"))
ixTail    <- which(is.na(tableTail$toCoast.y))
if(length(ixTail) !=1) stop("expect one tail")
coastConnect$toCoast[ixTail] <- integerMissing

# find the coastal segments at the head of the line
tableHead <- left_join(x=coastConnect, y=coastConnect %>% st_set_geometry(NULL), by=c("segId"="toCoast"))
ixHead    <- which(is.na(tableHead$segId.y))
if(length(ixHead) !=1) stop("expect one head")

# identify the index of the toCoast segments
nCoast    <- length(coastConnect$segId)
tableOrig <- cbind(select(coastConnect %>% st_set_geometry(NULL), segId, toCoast), toCoastIx=seq(1:nCoast))
tableJoin <- left_join(x=coastConnect, y=tableOrig, by=c("toCoast"="segId"))

# re-define the landmass ID
coastConnect$idLandmass <- rep(integerMissing, nCoast)

# initialize
idLand <- 1L
jCoast <- ixHead

# navigate the coastline
for (iCoast in 1:nCoast){

 # get the next index
 kCoast <- tableJoin$toCoastIx[jCoast]
 if(coastConnect$toCoast[jCoast] != integerMissing){
  if(coastConnect$toCoast[jCoast] != coastConnect$segId[kCoast]) stop("mismatched segId")
 } # check connections
 #print(paste(coastConnect$segId[jCoast], coastConnect$toCoast[jCoast]))

 # assign the landmass ID
 coastConnect$idLandmass[jCoast] <- idLand

 # update the landmass ID
 if(coastConnect$idLandmass[kCoast] != integerMissing | coastConnect$toCoast[jCoast] == integerMissing){
  idLand <- idLand+1L
  if(sum(coastConnect$idLandmass != integerMissing) == nCoast) break
  jCoast <- min(which(coastConnect$idLandmass == integerMissing))
  next
 } # if updating the landmass 
 
 # update connection
 jCoast <- kCoast

}  # looping through coastline segments

# check
if(sum(coastConnect$idLandmass != integerMissing) != nCoast) stop("have not assigned all segments")

# write overlapping regions
coastContinent_shp <- paste(shape_path, "coastContinent.shp", sep="")
write_sf(coastConnect, coastContinent_shp)
