library(sf)
library(dplyr)
library(tictoc)

#' orderCoastline
#' @description order coastline w.r.t coastline connections
orderCoastline <- function(coastConnect) {

# arguments
# coastConnect = coastline data frame 

# initialize
coastOrder <- coastConnect

# rank the segId and toCoast vectors
rankVec  <- as.data.frame(cbind(segId=order(coastConnect$segId),toCoast=order(coastConnect$toCoast)))
segIndex <- rankVec[order(rankVec$toCoast),]

# test that we got all segments
v1   <- coastConnect$segId[rankVec$segId]
v2   <- coastConnect$toCoast[rankVec$toCoast]
if(length(which(v1-v2 !=0)) > 0) stop("have not assigned all coastline segments")

# initialize the coastline
nCoast     <- length(coastConnect$segId)
ixCurrent  <- which.min(coastConnect$segId)  # initialize the coastline segment (gotta start somehwere)
#coastOrder <- coastConnect[ixCurrent,]       # get the first row
coastOrder$index[1] <- ixCurrent

# loop through the coastline segments
for (iNavigate in 2:nCoast){  # nCoast-1 because don't want to duplicate the first segment

 # identify the next coastal index
 ixNext <- segIndex$segId[ixCurrent]
 if(coastConnect$toCoast[ixCurrent] != coastConnect$segId[ixNext]) stop("cannot find connecting segment")
 #print(c(iNavigate, ixCurrent, ixNext, coastConnect$toCoast[ixCurrent], coastConnect$segId[ixNext]))

 # get the next segment
 ixCurrent  <- ixNext
 coastOrder$index[iNavigate] <- ixCurrent

 #coastOrder <- rbind(coastOrder, coastConnect[ixCurrent,])

} # looping through the coastline segments

return(coastOrder)
}
