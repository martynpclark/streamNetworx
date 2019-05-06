library(tools)
library(ncdf4)
source("getGridIndices.R")

#' makeSpatialWeights
#' @description Creates a spatial weights file
makeSpatialWeights <- function(input_ncdf, output_ncdf, targetId, overlapId, weights) {

# arguments
# input_ncdf:  input NetCDF file (the overlapping polygons [e.g., grid cells])
# output_ncdf: output NetCDF file (the spatial weights file)
# targetId:    ID of target polygon (e.g., basin, lake)
# overlapId:   ID of overlapping polygons (e.g., a grid cell)
# weights:     weights assigned to each overlapping polygon

# get the run lengths
runLength <- rle(targetId)

# get the grid indices (and check if a 2-d grid)
gridIndices <- getGridIndices(input_ncdf, overlapId)
is2dGrid <- (gridIndices$i_grid[1] > 0 & gridIndices$j_grid[1] > 0)

# remove the NetCDF file -- R does not seem to have a "clobber" option
system(paste("rm -f",output_ncdf))

# define dimensions
polygon_dim <- ncdim_def("polyid",    "", runLength$values)
overlap_dim <- ncdim_def("overlapid", "", overlapId)

# define variables
nOverlaps_def <- ncvar_def("nOverlaps", "-", polygon_dim, -9999, "Number of intersecting polygons", prec="short")
IDmask_def    <- ncvar_def("IDmask",    "-", overlap_dim, -9999, "Polygon ID (polyid) associated with each record", prec="integer")
weight_def    <- ncvar_def("weight",    "-", overlap_dim,  1e32, "fraction of polygon(polyid) intersected by polygon identified by poly2", prec="double")
i_grid_def    <- ncvar_def("i_grid",    "-", overlap_dim, -9999, "Index in the x dimension of the raster grid (starting with 1,1 in LL corner)", prec="integer")
j_grid_def    <- ncvar_def("j_grid",    "-", overlap_dim, -9999, "Index in the y dimension of the raster grid (starting with 1,1 in LL corner)", prec="integer")

# create NetCDF file
if(is2dGrid){ # include i and j indices
 ncout <- nc_create(output_ncdf,list(nOverlaps_def,IDmask_def,weight_def,i_grid_def,j_grid_def),force_v4=T)
} else {
 ncout <- nc_create(output_ncdf,list(nOverlaps_def,IDmask_def,weight_def),force_v4=T)
}

# put variables
ncvar_put(ncout, nOverlaps_def, runLength$length)
ncvar_put(ncout, IDmask_def,    targetId)
ncvar_put(ncout, weight_def,    weights)

# put i and j indices (if needed)
if(is2dGrid){ # include i and j indices
 ncvar_put(ncout, i_grid_def, gridIndices$i_grid)
 ncvar_put(ncout, j_grid_def, gridIndices$j_grid)
}

# close the file, writing data to disk
nc_close(ncout)

return(is2dGrid)
}
