library(sf)
library(dplyr)
library(lwgeom)
library(tictoc)
library(data.table)
source("area_weighted.R")
source("makeGridSubset.R")
source("makeSpatialWeights.R")
source("lake_stream_intersect.R")
source("lake_stream_connections.R")

# define projection
proj <- 3408  # NOTE: 3408 is equal area Northern Hemisphere. Need to change for other regions.

# define hydrography dataset
hydroDataset <- "merit"
#hydroDataset <- "hdma"

# define the variable names for hydroLakes
id_lakes   <- "Hylak_id"

# define the variable names for the hydrography dataset

# (1) MERIT hydrography
if(hydroDataset == "merit"){
 id_streams   <- "COMID"
 name_upsArea <- "uparea"

# (2) HDMA hydrography
} else {
 id_streams   <- "PFAF_CODE"
 name_upsArea <- "flow_acc"
}

# Define grid name (subset)
subsetName <- "LakePowell"

# -----
# * define files...
# -----------------

# define input paths 
merit_path <- "/Users/mac414/geospatial_data/MERIT-hydro/pfaf_level_02/"
grid_path  <- "/Users/mac414/geospatial_data/MERIT-hydro/globalGrid/cru360x720/"
hdma_path  <- "/Users/mac414/geospatial_data/HDMA/streams/"
lake_path  <- "/Users/mac414/geospatial_data/hydroLakes/HydroLAKES_polys_v10_shp/"

# Define the output path
outputPath = "/Users/mac414/geospatial_data/stream2lakes/"

# define shapefiles for the river network
if(hydroDataset == "merit"){
 stream_shp <- paste(merit_path, "riv_pfaf_77_MERIT_Hydro_v07_Basins_v01.shp", sep="")
} else {
 stream_shp <- paste(hdma_path, "na_streams_colorado.shp", sep="")
}

# define shapefiles for the lakes
lake_shp   <- paste(lake_path,  "NorthAmericaLakes_big.shp", sep="")

# define NetCDF file that describes the CTSM grid
grid_nc   <- paste(grid_path, "cru360x720.nc", sep="")
grid_pref <- paste(file_path_sans_ext(basename(grid_nc)), hydroDataset, sep='_')

# get additional names to define the grid
gridNames <- data.table(grid_nc = grid_nc,
                        grididx = paste(grid_path, grid_pref, "_idx.nc", sep=""),
                        tiforig = paste(grid_path, grid_pref, "_idx.tif", sep=""),
                        tifproj = paste(grid_path, grid_pref, "_idx.proj.tif", sep=""),
                        tif_sub = paste(grid_path, grid_pref, "_idx.", subsetName, ".tif", sep=""),
                        shporig = paste(grid_path, grid_pref, "_idx.", subsetName, ".shp", sep=""),
                        shpproj = paste(grid_path, grid_pref, "_idx.", subsetName, ".", proj, ".shp", sep="") )

# define output names for tsv files
grid2lake_tsv   <- paste(outputPath, "grid2lake.tsv", sep="")
stream2lake_tsv <- paste(outputPath, "stream2lake", hydroDataset, ".tsv", sep="")

# define output names for shapefiles
grid2lake_shp   <- paste(outputPath, "grid2lake.shp", sep="")
stream2lake_shp <- paste(outputPath, "stream2lake", hydroDataset, ".shp", sep="")

# define output names for netcdf files
grid2lake_nc   <- paste(outputPath, "grid2lake.nc", sep="")
stream2lake_nc <- paste(outputPath, "stream2lake", hydroDataset, ".nc", sep="")

# -----
# * get spatial files transformed to projection EPSG:proj...
# ----------------------------------------------------------

tic("read the stream/lake shapefiles")
stream_orig <- read_sf(stream_shp)
lake_orig   <- read_sf(lake_shp)
toc()  # print timing

# get the bounding box from the stream network subset
bbox <- st_bbox(stream_orig)

# convert to the desired projection
tic("transform coordinates")
stream_proj <- st_transform(stream_orig, proj)
lake_proj   <- st_transform(lake_orig, proj) %>% st_buffer(0)
toc()  # print timing

# rename desired variables (so can access column using the "var_" name instead of the original name)
names(stream_proj) [names(stream_proj) == id_streams] <- "var_streams"
names(lake_proj)   [names(lake_proj)   == id_lakes]   <- "var_lakes"

# select desired variables
stream_proj <- stream_proj %>% select(var_streams)
lake_proj   <- lake_proj   %>% select(var_lakes)

# revert to the original names
names(stream_proj) [names(stream_proj) == "var_streams"] <- id_streams
names(lake_proj)   [names(lake_proj)   == "var_lakes"]   <- id_lakes

# get the lat-lon grid (transformed into the projection defined by EPSG:proj)
tic("get the lat-lon grid")
grid_proj <- makeGridSubset(gridNames, subsetName, proj, bbox)
toc()  # print timing

# -----
# * get the intersection between the streams and lakes...
# -------------------------------------------------------

# intersect streams and lakes
tic("intersect streams with the lake polygons")
rivUnderLake <- lake_stream_intersect(lake_proj, stream_proj)
toc()  # print timing

# get spatial connections between lakes and streams
stream2lake <- lake_stream_connections(stream_orig, rivUnderLake, id_lakes, id_streams, name_upsArea)

# write the shapefile
write_sf(stream2lake, stream2lake_shp)

# -----
# * get the intersection between the grid and lakes...
# ----------------------------------------------------

# intersect grids and lakes
tic("intersect grids with the lake polygons")
lake2grid_full <- area_weighted_intersection(lake_proj, grid_proj)
toc()  # print timing

# get the subset of lakes within the grid domain
lake2grid <- subset(lake2grid_full, lake2grid_full$hru_id != 'NA')

# make the spatial weights file
is2dGrid <- makeSpatialWeights(gridNames$grididx, grid2lake_nc, lake2grid$Hylak_id, lake2grid$hru_id, lake2grid$w)

# write intersections to a .tsv file
readr::write_tsv(lake2grid, grid2lake_tsv)
