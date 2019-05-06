library(sf)
library(lwgeom)

#' lake_stream_connections
#' @description get spatial connections between lakes and streams
lake_stream_connections <- function(streams, intersect, id_lakes, id_streams, id_upsArea) {

# replace the name of the streams object with something more generic
names(streams)    [names(streams)   == id_streams] <- "var_streams"
names(streams)    [names(streams)   == id_upsArea] <- "var_upsArea"

# replace the name of the intersect object with something more generic
names(intersect)  [names(intersect) == id_lakes]   <- "var_lakes"
names(intersect)  [names(intersect) == id_streams] <- "var_streams"
names(intersect)  [names(intersect) == id_upsArea] <- "var_upsArea"

# join the upstream area for each stream segment in the intersect table
mergedTable <- merge(x=intersect, y=streams[ , c("var_streams", "var_upsArea")], by="var_streams", all.x=TRUE)

# get the subset table
subsetTable <- subset(mergedTable, mergedTable$var_lakes != 'NA')

# sort table by lake id to enable operations over all intersecting segments
sort_table  <- subsetTable[order(var_lakes,var_upsArea)]

# identify the number of intersecting stream segments for each lake
runLengths  <- rle(sort_table$var_lakes)
nSegPerLak  <- data.table(nStreams=runLengths$lengths, var_lakes=runLengths$values)

# initialize inflow and outflow
sort_table$inflow  <- 1L   # start with 1 and set to 0
sort_table$outflow <- 0L   # start with 0 and set to 1

# specify inflow and outflow
sort_table$inflow[cumsum(nSegPerLak$nStreams)]  <- 0L  # outflow so set inflow to 0
sort_table$outflow[cumsum(nSegPerLak$nStreams)] <- 1L  # outflow so set outflow to 1

# make sure the geometry column is last
# NOTE: Not sure if this is necessary
sort_table = sort_table %>% select(var_lakes, var_streams, fUnderLake, var_upsArea, inflow, outflow, geometry)

# get the subset of the table with more than one stream segment
# NOTE: one stream segment per lake means that the lake is entirely within the stream segment
#  -- for runLength=1 there could be multiple lakes in a single stream segment
mergeTable  <- left_join(sort_table, nSegPerLak, by="var_lakes")
subsetTable <- subset(mergeTable, mergeTable$nStreams > 1)

# remove the nStreams column (no longer needed)
subsetTable <- subsetTable[-grep('nStreams', colnames(subsetTable))]

# merge the intersections with the original shapefile
desiredVars <- c("var_streams", "var_lakes", "fUnderLake", "inflow", "outflow")
stream2lake <- merge(x=streams, y=subsetTable[ , desiredVars], by="var_streams", all.x=TRUE)

# add an ID
stream2lake <- cbind(id=rownames(stream2lake), stream2lake)

# modify variables where stream does not intersect with lake (NA)
stream2lake$fUnderLake[is.na(stream2lake$fUnderLake)] <- 0     # fraction under lake to zero
stream2lake$var_lakes [is.na(stream2lake$var_lakes) ] <- -9999 # HyLak_id to -9999
stream2lake$inflow    [is.na(stream2lake$inflow)    ] <- 0L    # inflow=0 
stream2lake$outflow   [is.na(stream2lake$outflow)   ] <- 0L    # outflow=0

# redefine column names
names(stream2lake)    [names(stream2lake)   == "var_lakes"]   <- id_lakes
names(stream2lake)    [names(stream2lake)   == "var_streams"] <- id_streams
names(stream2lake)    [names(stream2lake)   == "var_upsArea"] <- id_upsArea

# check that the field name is less than 10 characters
# NOTE -- if this happens, all names are abbreviated in a difficult-to-decipher manner
cNames <- names(stream2lake)
if(any(nchar(cNames) > 10)){
 print(cNames)
 stop("One of the field names is greater than 10 characters: Fix")
}

# return the connections between streams and lakes
return(stream2lake)
}
