library(tools)
library(ncdf4)
library(sf)
library(dplyr)
library(tictoc)
library(data.table)
source("/Users/mac414/analysis/poly2poly_R/area_weighted.R")

# logical definitions
yes <- 1
no  <- 0

#####
# DEFINE FILES...
#################

# define projection
#proj <- 5070  # NOTE: 5070 is CONUS Albers. Need to change for other regions.
#proj <- 3035  # NOTE: 3035 is Europe equal area. Need to change for other regions.
#proj <- 7722  # NOTE: 1121 is India. Need to change for other regions.
proj <- 3408  # NOTE: 3408 is equal area Northern Hemisphere. Need to change for other regions.

# define subregion
#merit_sub <- "cat_pfaf_23"   # Central Europe
merit_sub <- "cat_pfaf_45"   # South Asia
#merit_sub <- "cat_pfaf_74"   # Misissippi

# define paths
base_path <- "/Users/mac414/geospatial_data/MERIT-hydro/"
grid_path <- paste(base_path, "globalGrid/cru360x720/", sep="")
cat_path  <- paste(base_path, "geopackage/", sep="")

# define files/paths
cru_nc     <- paste(grid_path, "cru360x720.nc", sep="")
cru_gdb    <- paste(grid_path, "cru360x720_idx.gpkg", sep="")
merit_gdb  <- paste(cat_path,  merit_sub, "_MERIT_Hydro_v07_Basins_v01.gpkg", sep="")
merit_proj <- paste(cat_path,  "proj/", merit_sub, "_MERIT_Hydro_v07_Basins_v01.shp", sep="")

# get the name of the layers
cru_layer   <- file_path_sans_ext(basename(cru_gdb))
merit_layer <- file_path_sans_ext(basename(merit_gdb))

# get the name of the tsv file
output_tsv  <- paste(base_path, "mizuRoute/ancillary_data/mapping/", merit_layer, ".tsv", sep="")
output_ncdf <- paste(base_path, "mizuRoute/ancillary_data/mapping/", merit_layer, ".nc", sep="")

# define number of lat/lon points
# NOTE: could obtain from the NetCDF file
nlat <- 360
nlon <- 720

# define flag if we need the grid
needGrid <- yes
#needGrid <- no

# define flag that we have completed the intersection
#done <- yes
done <- no

#####
# GET THE CRU GRID...
#####################

# get the name of the new files
ncindex <- paste(grid_path, file_path_sans_ext(basename(cru_nc)), "_idx.nc", sep="")
tiforig <- paste(grid_path, file_path_sans_ext(basename(cru_nc)), "_idx.tif", sep="")
tifproj <- paste(grid_path, file_path_sans_ext(basename(cru_nc)), "_idx.proj.tif", sep="")
tif_sub <- paste(grid_path, file_path_sans_ext(basename(cru_nc)), "_idx.subset.tif", sep="")
shporig <- paste(grid_path, file_path_sans_ext(basename(cru_nc)), "_idx.shp", sep="")
shpproj <- paste(grid_path, file_path_sans_ext(basename(cru_nc)), "_idx.proj.shp", sep="")

# get the original merit polygons
tic("read the MERIT polygons")
merit <- read_sf(merit_gdb, merit_layer)
toc()  # print timing

# get the bounding box from the MERIT subset
bbox <- st_bbox(merit)

# define spatial window as a string
buffer <- 0.5  # degrees
window <- paste(bbox[1]-buffer, bbox[4]+buffer, bbox[3]+buffer, bbox[2]-buffer)

# check if need to process the grid
if(needGrid==yes){

# use NCO to add indices to the NetCDF file
# NOTE: landmask is just a 2d array used to size the array operation
system(paste('ncap2 --overwrite -s "hru_id=array(1,1,landmask)"', cru_nc, ncindex))

# use gdal_translate to convert the NetCDF file to a .tif and label with the hru_id
system(paste('gdal_translate -of Gtiff NETCDF:"', ncindex, '":hru_id ', tiforig, sep=""))
system(paste("gdal_translate -a_srs EPSG:4326", tiforig, tifproj)) # add projection information to the .tif

# use gdal_translate to get a spatial subset
system(paste("gdal_translate -projwin", window, "-of GTiff", tifproj, tif_sub))

# polygonize the .tif
tic("created the cru shapefile")
system(paste("rm -f",shporig)) # remove existing shapefile if it exists
system(paste("gdal_polygonize.py", tif_sub, '-f "ESRI Shapefile"', shporig, file_path_sans_ext(basename(shporig)), "hru_id"))
toc()  # print timing

# create a geopackage
tic("created the cru geopackage")
system(paste("ogr2ogr -f GPKG", cru_gdb, shporig))
toc()  # print timing

# convert to the new projection
tic("converted to the new projection (just to visualize)")
system(paste('ogr2ogr -f "ESRI Shapefile" -t_srs EPSG:', proj, " ", shpproj, " ", shporig, sep=""))
toc()  # print timing

}  # if we need the grid

#####
# READ FILES...
###############

# check if done already
if(done==no){

# read CRU polygons
tic("read the CRU polygons")
cru <- read_sf(cru_gdb, cru_layer) %>%
               st_transform(proj) %>%
               st_buffer(0) %>%
               select(hru_id)
toc()  # print timing

# read MERIT polygons
tic("read the MERIT polygons")
merit <- read_sf(merit_gdb, merit_layer) %>%
                 st_transform(proj) %>%
                 st_buffer(0) %>%
                 select(COMID)
toc()  # print timing

# write the reprojected MERIT polygons (just for testing)
tic("write the reprojected MERIT polygons")
write_sf(merit, merit_proj)
toc()  # print timing

} # if done already

#####
# INTERSECT SHAPES...
#####################

# check if done already
if(done==no){

# intersect catchments
tic("intersect CRU grids with the MERIT catchments")
intersected <- area_weighted_intersection(merit, cru)
toc()  # print timing

# write intercetions
readr::write_tsv(intersected, output_tsv)

} # if done already

# read the tsv file
if(done==yes){
 intersected <- read.table(file = output_tsv, sep = '\t', header = TRUE)
}

#####
# GET ADDITIONAL INFORMATION...
###############################

# read the hru_id (just to check we got the indices correctly)
ncid   <- nc_open(ncindex)
idGrid <- ncvar_get(ncid, var='hru_id')
nc_close(ncid)

# get the grids
j_grid <- ceiling(intersected$hru_id/nlon)
i_grid <- intersected$hru_id - (j_grid-1)*nlon

# test
ixStart <- 1000
ixCount <- 10
for (ix in (ixStart):(ixStart+ixCount)){
  print(paste("check hru_id:",i_grid[ix],j_grid[ix],intersected$hru_id[ix],idGrid[i_grid[ix],j_grid[ix]]))
}

# get the run lengths
overlap <- rle(intersected$COMID)

#####
# WRITE INFORMATION TO THE NETCDF FILE...
#########################################

# remove the NetCDF file -- R does not seem to have a "clobber" option
system(paste("rm -f",output_ncdf))

# define dimensions
polygon_dim <- ncdim_def("polyid",    "", overlap$values)
overlap_dim <- ncdim_def("overlapid", "", intersected$hru_id)

# define variables
nOverlaps_def <- ncvar_def("nOverlaps", "-", polygon_dim, -9999, "Number of intersecting polygons", prec="short")
IDmask_def    <- ncvar_def("IDmask",    "-", overlap_dim, -9999, "Polygon ID (polyid) associated with each record", prec="integer") 
weight_def    <- ncvar_def("weight",    "-", overlap_dim,  1e32, "fraction of polygon(polyid) intersected by polygon identified by poly2", prec="double")
i_grid_def    <- ncvar_def("i_grid",    "-", overlap_dim, -9999, "Index in the x dimension of the raster grid (starting with 1,1 in LL corner)", prec="integer")
j_grid_def    <- ncvar_def("j_grid",    "-", overlap_dim, -9999, "Index in the y dimension of the raster grid (starting with 1,1 in LL corner)", prec="integer")
 
# create NetCDF file
ncout <- nc_create(output_ncdf,list(nOverlaps_def,IDmask_def,weight_def,i_grid_def,j_grid_def),force_v4=T)

# put variables
ncvar_put(ncout, nOverlaps_def, overlap$length)
ncvar_put(ncout, IDmask_def,    intersected$COMID)
ncvar_put(ncout, weight_def,    intersected$w)
ncvar_put(ncout, i_grid_def,    i_grid)
ncvar_put(ncout, j_grid_def,    j_grid)

# close the file, writing data to disk
nc_close(ncout)
