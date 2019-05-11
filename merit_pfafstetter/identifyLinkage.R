library(sf)
library(dplyr)
library(units)
library(tictoc)

#' identify linkage
#' @description identify the spatial linkage between "basePoint" and "nextPoint" objects
identifyLinkage <- function(basePoints, nextPoints) {

# arguments
# basePoints = sf object, collection of points (e.g., start points of coastline segments)
# nextPoints = sf object, collection of points (e.g., end points in coastline segments)

# for example, ask which point at the end of a segment is the same as the point at the start of a segment, e.g., 
#   which coastline end is connected to a given coastline start (save id of coastline start)
#   which coastline end is connected to a given stream segment (save id of stream segment)
#
# so identify the next point (coastline start / stream segment) that is connected "to" the base point

# replace the name of the ID with something more generic
idBase <- names(basePoints)[names(basePoints) != attr(basePoints, "sf_column")]
idNext <- names(nextPoints)[names(nextPoints) != attr(nextPoints, "sf_column")]

# replace the name of the ID with something more generic
names(basePoints)[names(basePoints) == idBase] <- "idGeneric"
names(nextPoints)[names(nextPoints) == idNext] <- "idGeneric"

# define the distance tolerance
tolDist <- set_units(10, m)   # 10 meters

# define "to" point
toPoints <- rep(-9999L, length(basePoints$idGeneric) )

# loop through the base points
for(i in 1:length(basePoints$idGeneric)){
 distance <- st_distance(nextPoints,basePoints[i,])  # distance between all "next" points and a given "base" point
 closest  <- which.min(distance)                     # the closest "next" point
 if(distance[closest] < tolDist) toPoints[i] <- nextPoints$idGeneric[closest]  # the ID of the next point that the base point connects "to"
}  # looping through the base points

# change the name of the input column to the name from the input file
names(basePoints)[names(basePoints) == "idGeneric"] <- idBase
names(nextPoints)[names(nextPoints) == "idGeneric"] <- idNext

return(toPoints)
}
