
# PROCESS FOR DEFINING PFAFSTETTER CODES

## Revised IDL code for
## A) Pfafstetter numbering; and
## B) Basin aggregation

--------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------
# GENERAL ROUTINES

- `get_attributes.pro`                       -- read attributes from a shapefile
- `get_shapes.pro`                           -- read shapes from a shapefile

- `defineAttributes.pro`                     -- define attributes in a shapefile
- `writeAttributes.pro`                      -- write attributes to a shapefile
- `writeShapefile.pro`                       -- write shapes to a shapefile

- `match.pro`                                -- matches vectors

- `danglePfafstetter.pro`                    -- gets Pfafstetter codes upstream of a given point in the network
   - `crawlUpstream.pro`
   - `get_PfafsCode.pro`

--------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------

# PART A: DEFINE PFAFSTETTER CODES

--------------------------------------------------------------------------------------------------------
## A1. Identify overlap between HUC and HDMA polygons for each NHD+ catchment

### *Source code*
- `nhd2hdma.R`                                -- identify overlap between HUC polygons and NHD+ catchments
- `nhd2huc12.R`                               -- identify overlap between HDMA polygons and NHD+ catchments
   - `area_weighted.R`                       -- general area overlap routine (from David Blodgett)

- `extractShapeSubset.bash`                   -- bash script to extract subsets from shape file
- `test_nhd2huc12.R`                         -- test R script to handle slow processing times in the Great Lakes

- `add_hdmaHUC.pro`                          -- assign the "most overlapping" HDMA/HUC polygon to NHD+ polygons

### *Inputs*
- `nhdPlus_geopackage/`                      -- directory with NHD+ regional shapefiles
- `HDMA/catch/na_catch.gpkg`                 -- HDMA shapefile
- `HUC/HUC_geopackage/huc12_conus.gpkg`     -- HUC-12 shapefile

### *Outputs*
- `nhdPlus_HDMA_mapping/[subregion].tsv`     -- overlap between HDMA polygons and NHD+ catchments
- `nhdPlus_HUC12_mapping/[subregion].tsv`    -- overlap between HUC-12 polygons and NHD+ catchments
- `nhdPlus_SHPs_HDMA-HUC12/[subregion].shp` -- "most overlapping" HDMA/HUC polygon in each NHD+ polygons

--------------------------------------------------------------------------------------------------------
## A2. Identify Pfafstetter codes for the coastline

### *Source code*
- `coastPfafstetter.pro`                      -- identify Pfafstetter codes for the coastline (including the Great Lakes)

### *Inputs*
- `HDPlus2_updated-CONUS.nc`                 -- mizuRoute network topology file
- `nhdPlus_raw/[subregion].shp`              -- raw NHD-Plus shapefiles

### *Outputs* (shapefiles in directory `nhdPlus_SHPs_coast/`)
- `conusCoast_pfaf-init.shp`                 -- initial coastline segments
- `conusCoast_pfaf1.shp`                     -- Pfafstetter level 1
- `conusCoast_pfaf2.shp`                     -- Pfafstetter level 2
- `conusCoast_pfaf-all.shp`                  -- Pfafstetter all levels

--------------------------------------------------------------------------------------------------------
## A3. Assign Pfafstetter codes for basins that reach the coast

### *Source code*
- assignCoastDangle.pro                      -- compute pfafstetter indices for dangling reaches at the coast 

### *Inputs*
- `NHDPlus2_updated-CONUS.nc`                -- mizuRoute network topology file
- `nhdPlus_final/Flowline`_*subregion*`.shp` -- merged oCONUS NHD-Plus shapefiles
- `conusCoast_pfaf-all.shp`                  -- Pfafstetter all levels for dangling reaches at the coast

### *Outputs* (shapefiles in `nhdPlus_SHPs_coastDangle/`)
- `Flowline`_*subregion*`.shp`

--------------------------------------------------------------------------------------------------------
## A4. Assign Pfafstetter codes for basins that DO NOT reach the coast

### *Source code*
- `assignOtherDangle.pro`                      -- compute pfafstetter indices for dangling reaches that do not reach the coast

### *Inputs*
- `NHDPlus2_updated-CONUS.nc`                  -- mizuRoute network topology file
- `nhdPlus_final/Flowline`_*subregion*`.shp`   -- merged oCONUS NHD-Plus shapefiles
- `conusCoast_pfaf-all.shp`                    -- Pfafstetter all levels for dangling reaches at the coast

### *Outputs* (shapefiles in `nhdPlus_SHPs_allDangle/`)
- `Flowline`_*subregion*`.shp`

--------------------------------------------------------------------------------------------------------
## A5. Assign new Pfafsttter codes to duplicate reaches

### *Source code*
- `assignDuplicate.pro`                      -- assign new Pfafsttter codes to duplicate reaches

### *Inputs* (shapefiles in `nhdPlus_SHPs_allDangle/`)
- `Flowline`_*subregion*`.shp`

### *Outputs* (shapefiles in `nhdPlus_SHPs_noDuplicate/`)
- `Flowline`_*subregion*`.shp`

--------------------------------------------------------------------------------------------------------
## A6. Assign Pfafstetter codes to basin

### *Source code*
- `assignBasins.pro`                         -- assign Pfafstetter codes to basins 

### *Inputs* (shapefiles in `nhdPlus_SHPs_noDuplicate/`)
- `Flowline`_*subregion*`.shp`

### *Outputs* (shapefiles in `nhdPlus_SHPs_noDuplicate/`)
- `Catchment`_*subregion*`.shp`

--------------------------------------------------------------------------------------------------------
## A7. Build a NetCDF file 

### *Source code*
- buildNetCDF.pro                            -- used to write Pfafsteter codes to NetCDF files

### *Inputs* (shapefiles in `nhdPlus_SHPs_noDuplicate/`)
- `Flowline`_*subregion*`.shp`
- `Catchment`_*subregion*`.shp`

### *Output*
- `conusPfafstetter.nc`

--------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------

# PART B: BASIN AGGREGATION 

--------------------------------------------------------------------------------------------------------
## B1. Aggregate basins based on the Pfafstetter code 

### *Source code*
- `aggregatePfaf.pro`                         -- aggregate basins based on the Pfafstetter code
   - `locationDangle.pro`                     -- identify the end point of each reach
   - `getAggregationIndices.pro`              -- get indices for aggregated polygons
      - `aggregateReaches.pro`                -- identify reaches to aggregate 

### *Inputs*
- `conusPfafstetter.nc`

### *Outputs*
- `conusPfafstetter_aggregate.nc`

--------------------------------------------------------------------------------------------------------
