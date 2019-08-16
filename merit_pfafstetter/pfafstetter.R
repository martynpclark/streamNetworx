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




