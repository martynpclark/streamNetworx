
PROCESS FOR DEFINING PFAFSTETTER CODES

Revised IDL code for Pfafstetter numbering

--------------------------------------------------------------------------------------------------------
0. General routines
- get_attributes.pro                       -- read attributes from a shapefile
- get_shapes.pro                           -- read shapes from a shapefile

- defineAttributes.pro                     -- define attributes in a shapefile
- writeAttributes.pro                      -- write attributes to a shapefile
- writeShapefile.pro                       -- write shapes to a shapefile

- match.pro                                -- matches vectors

- danglePfafstetter.pro                    -- gets Pfafstetter codes upstream of a given point in the network
   - crawlUpstream.pro
   - get_PfafsCode.pro

--------------------------------------------------------------------------------------------------------
1. Identify overlap between HUC and HDMA polygons for each NHD+ catchment

** Source code
- nhd2hdma.R                               -- identify overlap between HUC polygons and NHD+ catchments
- nhd2huc12.R                              -- identify overlap between HDMA polygons and NHD+ catchments
   - area_weighted.R                       -- general area overlap routine (from David Blodgett)

- extractShapeSubset.bash                  -- bash script to extract subsets from shape file
- test_nhd2huc12.R                         -- test R script to handle slow processing times in the Great Lakes

- add_hdmaHUC.pro                          -- assign the "most overlapping" HDMA/HUC polygon to NHD+ polygons

** Inputs
- nhdPlus_geopackage/                      -- directory with NHD+ regional shapefiles
- HDMA/catch/na_catch.gpkg                 -- HDMA shapefile
- HUC/HUC_geopackage/huc12_conus.gpkg      -- HUC-12 shapefile

** Outputs
- nhdPlus_HDMA_mapping/[subregion].tsv     -- overlap between HDMA polygons and NHD+ catchments
- nhdPlus_HUC12_mapping/[subregion].tsv    -- overlap between HUC-12 polygons and NHD+ catchments
- nhdPlus_SHPs_HDMA-HUC12/[subregion].shp  -- "most overlapping" HDMA/HUC polygon in each NHD+ polygons

--------------------------------------------------------------------------------------------------------
2. Identify Pfafstetter codes for the coastline

** Source code
- coastPfafstetter.pro                     -- identify Pfafstetter codes for the coastline (including the Great Lakes)

** Inputs
- NHDPlus2_updated-CONUS.nc                -- mizuRoute network topology file
- nhdPlus_raw/[subregion].shp              -- raw NHD-Plus shapefiles

** Outputs (shapefiles in directory nhdPlus_SHPs_coast/)
- conusCoast_pfaf-init.shp                 -- initial coastline segments
- conusCoast_pfaf1.shp                     -- Pfafstetter level 1
- conusCoast_pfaf2.shp                     -- Pfafstetter level 2
- conusCoast_pfaf-all.shp                  -- Pfafstetter all levels

--------------------------------------------------------------------------------------------------------
3. Assign Pfafstetter codes for basins that reach the coast

** Source code
- assignCoastDangle.pro                    -- compute pfafstetter indices for dangling reaches at the coast 

** Inputs
- NHDPlus2_updated-CONUS.nc                -- mizuRoute network topology file
- nhdPlus_final/Flowline_[subregion].shp   -- merged oCONUS NHD-Plus shapefiles
- conusCoast_pfaf-all.shp                  -- Pfafstetter all levels for dangling reaches at the coast

** Outputs (shapefiles in nhdPlus_SHPs_coastDangle/)
- Flowline_[subregion]'.shp'






3. Identify dangling reaches across the CONUS

** Source code
- identifyDangle.pro                       -- Identify dangling reaches across the CONUS

** Inputs
- NHDPlus2_updated-CONUS.nc                -- mizuRoute network topology file
- nhdPlus_SHPs_final/[subregion].shp       -- Shapefiles for NHD+ flowlines

** Outputs
- nhdPlus_SHPs_dangle/conusDangle.sh       -- shapefiles for the dangling reaches






 

