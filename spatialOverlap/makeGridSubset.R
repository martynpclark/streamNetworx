library(sf)
library(tools)
library(tictoc)

#' makeGrid
#' @description Creates a shapefile from the land model grid
makeGridSubset <- function(gridNames, subsetName, proj, bbox) {

# get the name of the new files
grid_nc <- gridNames$grid_nc  # original NetCDF grid file (full domain)
grididx <- gridNames$grididx  # netCDF grid file with hru_id (full domain)
tiforig <- gridNames$tiforig  # geotif of full domain
tifproj <- gridNames$tifproj  # geotif of full domain (with projection information [EPSG:4326])
tif_sub <- gridNames$tif_sub  # geotif of domain subset
shporig <- gridNames$shporig  # shapefile of domain subset (in projection EPSG:4326)
shpproj <- gridNames$shpproj  # reprojected shapefile of domain subset (in projection proj)

# ensure bounding box is 0-360
if(bbox[1] < 0) bbox[1]=bbox[1]+360
if(bbox[3] < 0) bbox[3]=bbox[3]+360

# define spatial subset as a string
buffer <- 1.0  # degrees
spatialSubset <- paste(bbox[1]-buffer, bbox[4]+buffer, bbox[3]+buffer, bbox[2]-buffer)

# use NCO to add indices to the NetCDF file
# NOTE: landmask is just a 2d array used to size the array operation
system(paste('ncap2 --overwrite -s "hru_id=array(1,1,landmask)"', grid_nc, grididx))

# use gdal_translate to convert the NetCDF file to a .tif and label with the hru_id
system(paste('gdal_translate -of Gtiff NETCDF:"', grididx, '":hru_id ', tiforig, sep=""))
system(paste("gdal_translate -a_srs EPSG:4326", tiforig, tifproj)) # add projection information to the .tif

# use gdal_translate to get a spatial subset
system(paste("gdal_translate -projwin", spatialSubset, "-of GTiff", tifproj, tif_sub))

# polygonize the .tif
tic("created the grid shapefile")
system(paste("rm -f",shporig)) # remove existing shapefile if it exists
system(paste("gdal_polygonize.py", tif_sub, '-f "ESRI Shapefile"', shporig, file_path_sans_ext(basename(shporig)), "hru_id"))
toc()  # print timing

# read the grid and transform to the desired projection
tic("read and transform the grid")
grid <- read_sf(shporig) %>%
                st_transform(proj) %>%
                st_buffer(0) %>%
                select(hru_id)
toc()  # print timing

# write the shapefile 
tic("write the reprojected shapefile (just to visualize)")
write_sf(grid, shpproj)
toc()  # print timing

return(grid)
}
