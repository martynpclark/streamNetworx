library(tools)
library(ncdf4)
library(sf)
library(dplyr)
library(tictoc)
library(data.table)
source("/Users/mac414/analysis/streamNetworx/spatialOverlap/area_weighted.R")
source("/Users/mac414/analysis/streamNetworx/spatialOverlap/makeGridSubset.R")
source("/Users/mac414/analysis/streamNetworx/spatialOverlap/makeSpatialWeights.R")

# logical definitions
yes <- 1
no  <- 0

# define hydro dataset
hydroDataset <- "merit"

# define subregion
merit_sub  <- "cat_pfaf_71"   # Saskatchewan-Nelson
subsetName <- "saskatchewan"

# define lat-lon projection
proj_wgs84 <- 4326 

# define projection
proj <- 3408  # NOTE: 3408 is equal area Northern Hemisphere. Need to change for other regions.

# define the variable names for the hydrography dataset
if(hydroDataset == "merit") id_basins<-"COMID" else id_basins<-"PFAF_CODE"

# -----
# * define files...
# -----------------

# define the base path
base_path <- "/Users/mac414/geospatial_data/"

# define input paths
merit_path <- paste(base_path, "MERIT-hydro/pfaf_level_02/", sep="")
grid_path  <- paste(base_path, "MERIT-hydro/globalGrid/cru360x720/", sep="")
hdma_path  <- paste(base_path, "HDMA/catch/", sep="")

# Define the output path
outputPath <- paste(base_path, "mizuRoute/ancillary_data/mapping/", sep="")

# define shapefiles for the river network
if(hydroDataset == "merit"){
 basin_shp <- paste(merit_path, merit_sub, "_MERIT_Hydro_v07_Basins_v01_bugfix1.shp", sep="")
} else {
 basin_shp <- paste(hdma_path, "na_catch.shp", sep="")
}

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

# define output names
grid2basin_tsv <- paste(outputPath, "grid2basin.tsv", sep="")
grid2basin_shp <- paste(outputPath, "grid2basin.shp", sep="")
grid2basin_nc  <- paste(outputPath, "grid2basin.nc",  sep="")

# -----
# * get spatial files transformed to projection EPSG:proj...
# ----------------------------------------------------------

tic("read the basin shapefiles")
basins_orig <- read_sf(basin_shp) %>% st_set_crs(proj_wgs84)
toc()  # print timing

# get the bounding box from the stream network subset
bbox <- st_bbox(basins_orig)

tic("transform coordinates")
basins_proj <- st_transform(basins_orig, proj) %>% st_buffer(0)
toc()  # print timing

# get the lat-lon grid (transformed into the projection defined by EPSG:proj)
tic("get the lat-lon grid")
grid_proj <- makeGridSubset(gridNames, subsetName, proj, bbox)
toc()  # print timing

# -----
# * get the intersection between the grid and basins...
# ----------------------------------------------------

# select "id" column in the shapefile
names(basins_proj)[names(basins_proj) == id_basins] <- "var_basins"  # change the name of the "id" column to "var_basins"
basins_proj <- basins_proj %>% select(var_basins)                    # select the ID column
names(basins_proj)[names(basins_proj) == "var_basins"] <- id_basins  # revert to the original column name

# intersect grids and basins
tic("intersect grids with the basin polygons")
basins2grid_full <- area_weighted_intersection(basins_proj, grid_proj)
toc()  # print timing

# get the subset of basins within the grid domain
basins2grid <- subset(basins2grid_full, basins2grid_full$hru_id != 'NA')

# write intersections to a .tsv file
readr::write_tsv(lake2grid, grid2lake_tsv)

# make the spatial weights file
names(basins2grid)[names(basins2grid) == id_basins] <- "var_basins"  # change the name of the "id" column to "var_basins"
is2dGrid <- makeSpatialWeights(gridNames$grididx, grid2basins_nc, basins2grid$var_basins, basins2grid$hru_id, basins2grid$w)
