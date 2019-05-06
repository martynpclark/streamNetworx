library(sf)
library(lwgeom)

#' lake_stream_intersect
#' @description get intersection between lakes and streams
lake_stream_intersect <- function(lakes, streams) {

# save the name that defines the  ID of the lakes and the streams
id_lakes   <- names(lakes)  [names(lakes)   != attr(lakes,   "sf_column")]
id_streams <- names(streams)[names(streams) != attr(streams, "sf_column")]

# replace the name with something more generic
names(lakes)  [names(lakes)   == id_lakes]   <- "var_lakes"
names(streams)[names(streams) == id_streams] <- "var_streams"

tic("intersect streams with the lake polygons")
intersect <- st_intersection(lakes, streams)
toc()  # print timing

tic("get the length under the lake")
lenUnderLake <- st_length(intersect)
toc()  # print timing

tic("get the length of each segment")
lenSegment <- st_length(streams)
toc()  # print timing

# create data table for subset of streams that intersect the lake polygons
rivUnderLake <- data.table(var_lakes=intersect$var_lakes, var_streams=intersect$var_streams)

# get the stream length for the subset of streams that intersect lakes
fullNetwork <- data.table(var_streams=streams$var_streams, lenFull=lenSegment)
subsetTable <- left_join(rivUnderLake, fullNetwork, by = "var_streams")

# get the fraction of each stream under a lake
rivUnderLake$fUnderLake <- lenUnderLake / subsetTable$lenFull

# redefine column names
setnames(rivUnderLake, c(id_lakes, id_streams, "fUnderLake"))

return(rivUnderLake)
}
