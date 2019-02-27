library(sf)
library(dplyr)
library(tictoc)
source("/Users/mac414/analysis/poly2poly_R/area_weighted.R")

# define layer name
layerName <- "Catchment_GL_04_HDMA363"

# define files/paths
test_path <- "/Users/mac414/geospatial_data/NHD_Plus/ancillary_data/nhdPlus_test/"
wbd_gdb   <- paste(test_path, "WBDHU12_REG04.gpkg", sep="")
nhd_gdb   <- paste(test_path, layerName, ".gpkg", sep="")

# define projection
proj <- 5070

# read HUC-12 polygons
tic("read the HUC-12 polygons")
wbd <- read_sf(wbd_gdb, "WBDHU12") %>%
               st_transform(proj) %>%
               st_buffer(0) %>%
               select(HUC12)
toc()  # print timing

# read NHD+ catchments
tic("read the NHD+ catchments")
nhd <- read_sf(nhd_gdb, layerName) %>%
               st_transform(proj) %>%
               st_buffer(0) %>%
               select(COMID = FEATUREID)
toc()  # print timing

# intersect catchments
tic("intersect NHD catchments and HUC12 polygons")
intersected <- area_weighted_intersection(nhd, wbd)
toc()  # print timing

# write intercetions
outputName <- paste(test_path, layerName, "_HUC12_intersection.tsv", sep="")
readr::write_tsv(intersected, outputName)
