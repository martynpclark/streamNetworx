library(sf)
library(dplyr)
library(tictoc)

#' extractPoint
#' @description Extract a point from a line string
extractPoint <- function(shapeLine, quantiles) {

# arguments
# shapeLine = shapefile with line strings 
# quantiles = vector of quantiles to sample 

# get the ID from the input shapefile
idInput <- names(shapeLine)[names(shapeLine) != attr(shapeLine, "sf_column")]

# replace the name of the ID with something more generic
names(shapeLine)[names(shapeLine) == idInput] <- "idGeneric"

# extract the point vector
pointVec <- st_line_sample(shapeLine, sample=quantiles)                 # extract the quantiles from the linestrings
pointVec <- st_sf(geometry=pointVec)                                    # convert to a spatial data frame
pointVec <- st_cast(pointVec, "POINT")                                  # ensure type POINT
pointVec <- cbind(idGeneric=as.integer(shapeLine$idGeneric), pointVec)  # add the ID

# change the name of the input column to the name from the input file
names(pointVec)[names(pointVec) == "idGeneric"] <- idInput  # change the name of the "id" column to input ID

return(pointVec)
}
