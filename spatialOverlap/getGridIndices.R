library(tools)
library(ncdf4)

#' getGridIndices
#' @description Convert hru_id to i and j indices
getGridIndices <- function(hruFile_nc, hruId_overlap) {

# arguments
# hruFile_nc = NetCDF file containing the HRU Id
# hru_id     = vector of hru Ids in the overlapping polygons

# read the hru ID -- could be a vector or a grid 
ncid   <- nc_open(hruFile_nc)
 hruId_file <- ncvar_get(ncid, var='hru_id')
nc_close(ncid)

# get the dimensions of the HRU file
dimLength <- dim(hruId_file)

# check if a 2-d array
if(length(dimLength) > 1){

 # get the number of latitude and longitude points
 nlon <- dimLength[1]
 nlat <- dimLength[2]

 # get the grids
 j_grid <- ceiling(hruId_overlap/nlon)
 i_grid <- hruId_overlap - (j_grid-1)*nlon

 # test
 for (ix in (1):(length(hruId_overlap))){
  if(hruId_overlap[ix] != hruId_file[i_grid[ix],j_grid[ix]]) stop("mismatch grid index")
 }

 # get table of grid indices
 gridIndices <- data.table(i_grid=i_grid, j_grid=j_grid)

# if a 1-d array
} else {
 gridIndices <- data.table(i_grid=c(-9999), j_grid=c(-9999))
}

# return grid indices
return(gridIndices)
}
