
PROCESS FOR DEFINING PFAFSTETTER CODES

Revised IDL code for Pfafstetter numbering

--------------------------------------------------------------------------------------------------------
0. General routines
- get_attributes.pro                       -- read attributes from a shapefile
- get_shapes.pro                           -- read shapes from a shapefile

- match.pro                                -- matches vectors

--------------------------------------------------------------------------------------------------------
1. Identify Pfafstetter codes for the coastline

** Source code
- coastPfafstetter.pro                     -- identify Pfafstetter codes for the coastline (including the Great Lakes)



- navigateCoastline.pro                    -- identify tributaries that drain to the coast 
- pfafCoastline.pro                        -- assign Pfafstetter codes to dangling reaches along the coastline
   - coastalTrib.pro                       -- subroutine to process coastal tributaries

** Inputs
- NHDPlus2_updated-CONUS.nc                -- mizuRoute network topology file
- nhdPlus_raw/*                            -- directory containing raw NHD-Plus shapefiles

** Outputs
- navigateCoast.nc                         -- codes for the coastline

--------------------------------------------------------------------------------------------------------
2. Identify Pfafstetter codes for the Great Lakes

** Source code
- navigateGreatLakes.pro                   -- assign Pfafstetter codes to dangling reaches around the Great Lakes

** Inputs
- NHDPlus2_updated-CONUS.nc                -- mizuRoute network topology file
- nhdPlus_raw/*                            -- directory containing raw NHD-Plus shapefiles

** Outputs
- navigateGreatLakes.nc                    -- codes for the Great Lakes

--------------------------------------------------------------------------------------------------------
3. Identify Pfafstetter codes for the CONUS

** Source code
- conusPfafsetter.pro                      -- assign Pfafstetter codes to all reaches in the CONUS
   - manualDangle.pro                      -- manually assign pfaf codes based on segId
   - danglePfafstetter.pro                 -- compute pfafstetter indices for a given dangling reach
   - crawlUpstream.pro                     -- crawl upstream and identify tributaries
   - get_PfafsCode.pro                     -- get the Pfafstetter code

** Inputs
- NHDPlus2_updated-CONUS.nc                -- mizuRoute network topology file
- NHDPlus2_reachCode.nc                    -- HUC codes for each reach
- navigateCoast.nc                         -- codes for the coastline
- navigateGreatLakes.nc                    -- codes for the Great Lakes
- nhdPlus_SHPs_final/*                     -- directory containing merged oCONUS NHD-Plus shapefiles

** Outputs
- conusPfafstetter_dangle.nc               -- Pfafstetter codes for all dangling reaches in the CONUS

--------------------------------------------------------------------------------------------------------
4. Assign new Pfafsttter codes to duplicate reaches

** Source code
- assignDuplicate.pro                      -- assign new Pfafsttter codes to duplicate reaches

** Inputs
- NHDPlus2_updated-CONUS.nc                -- mizuRoute network topology file
- NHDPlus2_reachCode.nc                    -- HUC codes for each reach
- conusPfafstetter_dangle.nc               -- Pfafstetter codes for all dangling reaches in the CONUS
- nhdPlus_SHPs_final/*                     -- directory containing merged oCONUS NHD-Plus shapefiles

** Outputs
- conusPfafstetter_noDuplicate.nc          -- Pfafstetter codes for all dangling reaches in the CONUS

--------------------------------------------------------------------------------------------------------
5. Add Pfafstetter codes to the shapefile

** Source code
- addShape_pfafstetter.pro                 -- add Pfafstetter codes to the shapefile

** Inputs
- NHDPlus2_updated-CONUS.nc                -- mizuRoute network topology file
- conusPfafstetter_noDuplicate.nc          -- Pfafstetter codes for all dangling reaches in the CONUS
- nhdPlus_SHPs_final/*                     -- directory containing merged oCONUS NHD-Plus shapefiles

** Outputs
- nhdPlus_SHPs_pfaf/*                      -- directory containing merged new shapefiles

--------------------------------------------------------------------------------------------------------
6. Assign new Pfafsttter codes to coastal catchments and endorheic basins

** Source code
- assignCoastline.pro                      -- assign new Pfafsttter codes to coastal catchments and endorheic basins

** Inputs
- NHDPlus2_updated-CONUS.nc                -- mizuRoute network topology file
- nhdPlus_SHPs_pfaf/*                      -- directory containing merged new shapefiles
- nhdPlus_raw/*                            -- directory containing raw NHD-Plus shapefiles

** Outputs
- conusPfafstetter_coastalCatchments.nc    -- new file with coastal catchments
- nhdPlus_SHPs_coast/*                     -- directory containing new shapefiles

--------------------------------------------------------------------------------------------------------
7. Define Pfafstetter classes for the river network 

** Source code
- aggregatePfaf.pro                        -- define Pfafstetter classes for the river network
   - locationDangle.pro                    -- identify the location of dangling reaches
   - getAggregationIndices.pro             -- get indices for a given aggregation level
   - aggregateReaches.pro                  -- aggregate reaches

** Inputs
- NHDPlus2_updated-CONUS.nc                -- mizuRoute network topology file
- conusPfafstetter_coastalCatchments.nc    -- Pfafstetter codes including coastal catchments
- nhdPlus_SHPs_final/*                     -- directory containing merged new shapefiles

** Outputs
- conusPfafstetter_aggregate.nc            -- aggregate (classified) Pfafstetter codes

--------------------------------------------------------------------------------------------------------
8. Add Pfafstetter codes to the shapefile (again) 

** Source code
- addShape_pfafstetter.pro                 -- add Pfafstetter codes to the shapefile

** Inputs
- NHDPlus2_updated-CONUS.nc                -- mizuRoute network topology file
- conusPfafstetter_aggregate.nc            -- Pfafstetter codes for all dangling reaches in the CONUS
- nhdPlus_SHPs_final/*                     -- directory containing merged oCONUS NHD-Plus shapefiles

** Outputs
- nhdPlus_SHPs_class/*                     -- directory containing shapefiles with the Pfafstetter classification

--------------------------------------------------------------------------------------------------------
9. Aggregate the mizuRoute control files

** Source code
- mizuRoute_aggregate.pro                  -- aggregate the mizuRoute control files
   - aggregateShapefile.pro                -- aggregate the shapefile

** Inputs
- NHDPlus2_updated-CONUS.nc                -- mizuRoute network topology file
- spatialweights_NLDAS12km_NHDPlus2_mod.nc -- spatial weights file
- conusPfafstetter_aggregate.nc            -- Pfafstetter codes for all dangling reaches in the CONUS
- nhdPlus_SHPs_class/*                     -- directory containing shapefiles with the Pfafstetter classification

** Outputs
- nhdPlus_SHPs_aggregate/*                 -- aggregated shapefiles
- network*-agg.nc                          -- aggregated network topology file (needed to run mizuRoute)
- spatialWeights*-agg.nc                   -- aggregated spatial weights file (needed to run mizuRoute)
