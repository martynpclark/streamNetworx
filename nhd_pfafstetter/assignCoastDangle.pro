pro assignCoastDangle

; Used to compute pfafstetter indices for dangling reaches at the coast

; get path to NHD-plus
nhd_root = '/Users/mac414/geospatial_data/NHD_Plus/ancillary_data/'

; define path for .sav files
savePath = nhd_root + 'idlSave/'

; *****
; * READ THE NHD+ TOPOLOGY...
; ***************************

; define the NetCDF file
nc_filename = nhd_root + 'NHDPlus2_updated-CONUS.nc'
print, 'Reading ancillary file'

; open file
nc_file = ncdf_open(nc_filename, /nowrite)

 ; get the segid
 ivar_id = ncdf_varid(nc_file,'link')
 ncdf_varget, nc_file, ivar_id, segId_mizu

 ; get the unique id of the next downstream segment
 ivar_id = ncdf_varid(nc_file,'to')
 ncdf_varget, nc_file, ivar_id, downSegId

 ; get the total area
 ivar_id = ncdf_varid(nc_file,'totalArea')
 ncdf_varget, nc_file, ivar_id, totalArea_mizu

 ; get the start index for immediate upstream reaches
 ivar_id = ncdf_varid(nc_file,'upSeg_start')
 ncdf_varget, nc_file, ivar_id, upSeg_start

 ; get the number of immediate upstream reaches
 ivar_id = ncdf_varid(nc_file,'upSeg_count')
 ncdf_varget, nc_file, ivar_id, upSeg_count

 ; get the ids for the immediate upstream stream segments
 ivar_id = ncdf_varid(nc_file,'upSegIds')
 ncdf_varget, nc_file, ivar_id, upSegIds
 
 ; get the indices for the immediate upstream stream segments
 ivar_id = ncdf_varid(nc_file,'upSegIndices')
 ncdf_varget, nc_file, ivar_id, upSegIndices

; close file
ncdf_close, nc_file

; *****
; * GET THE RAGGED ARRAY OF UPSTREAM INDICES...
; *********************************************

; convert to 0-based indices
upSeg_start  = upSeg_start-1
upSegIndices = upSegIndices-1

; define ragged array
nSeg     = n_elements(segId_mizu)
upsReach = ptrarr(nSeg, /allocate_heap)

; loop through reaches
for iSeg=0,nSeg-1 do begin

 ; if upstream reaches exist
 if(upSeg_count[iSeg] gt 0)then begin

  ; define indices
  i1 = upSeg_start[iSeg]
  i2 = upSeg_start[iSeg] + upSeg_count[iSeg] - 1

  ; populate the ragged array
  *(upsReach[iSeg]) = {upSegIds:upSegIds[i1:i2], upSegIndices:upSegIndices[i1:i2]}

 endif ; if upstream reaches exist

endfor ; populate the ragged array

; *****
; * MATCH CONUS DATASET WITH THE DANGLING REACHES AT THE COAST...
; ***************************************************************

; shapefile defining dangling reaches at the coast
shp_dangle = nhd_root + 'nhdPlus_SHPs_coast/conusCoast_pfaf-all.shp'

; get the attributes for the dangling reaches at the coast
get_attributes, shp_dangle, 'idUnique',  comId_dangle
get_attributes, shp_dangle, 'upsArea',   upsArea_dangle
get_attributes, shp_dangle, 'pfafCode',  pfafCode_dangle
get_attributes, shp_dangle, 'coastMask', coastMask_dangle

; match the dangling reaches with the coastal reaches
matchName = savePath + 'matchConusDangle.sav'
if(file_test(matchName) eq 0)then begin
 print, 'Matching the file ', matchName
 match, segId_mizu, comId_dangle, segIdCONUS_ix, dangle_ix
 save, segIdCONUS_ix, dangle_ix, filename=matchName
endif else begin
 restore, matchName
endelse

; define the number of dangling reaches
nDangle = n_elements(segIdCONUS_ix)

; *****
; * ASSIGN PFAFSTETTER CODES FOR THE DANGLING REACHES AT THE COAST...
; *******************************************************************

; define name of the IDL save file
pfafName = savePath + 'pfafstetter_coastalDangle.sav'
spawn, 'rm ' + pfafName

; check that the IDL save file exists
if(file_test(pfafName) eq 0)then begin

 ; define the maximum number of levels
 maxLevel = 19  ; cannot have numbers with more than 19 digits

 ; define the pfafstetter code
 mainStem = replicate(0L,  maxLevel,nSeg)
 pfafVec  = replicate(0LL, nSeg)

 ; sort the dangling reaches w.r.t. upstream area
 ixSort = reverse(sort(upsArea_dangle[dangle_ix]))

 ; loop through dangling reaches
 for iDangle=0,nDangle-1 do begin

  ; define indices in conus and dangling vectors
  iCONUS  = segIdCONUS_ix[ixSort[iDangle]]  ; index in conus vector
  jDangle = dangle_ix[ixSort[iDangle]]      ; index in dangling vector

  ; print progress
  pText = 'Processing dangling reach ' + strtrim(iDangle+1,2) + ' out of ' + strtrim(nDangle,2) + ': '
  if(iDangle lt 100 or iDangle mod 100 eq 0)then print, pText, pfafCode_dangle[jDangle], totalArea_mizu[iCONUS]
  
  ; check a valid Pfaf code
  if(coastMask_dangle[jDangle] eq 0)then stop, 'expect element drains to the coast'
  
  ; initialize the Pfafstetter code -- remove trailing zeroes
  strPfaf = strtrim(pfafCode_dangle[jDangle], 2)
  if(strpos(strPfaf,'0') gt 0)then strPfaf = strmid(strPfaf,0,strpos(strPfaf,'0',/reverse_search))
  
  ; initialize the Pfafstetter code -- get starting levels
  nLevels = strlen(strPfaf)
  iLevel  = nLevels-1 
  
  ; initialize the Pfafstetter code -- get pCode vector
  pCode = replicate(0L, maxLevel)
  for ix=0,nLevels-1 do pCode[ix] = strmid(strPfaf,ix,1)
  
  ; get the Pfafstetter codes
  danglePfafstetter, iLevel, iCONUS, pCode, segId_mizu, upSeg_count, upsReach, totalArea_mizu, $  ; input
                     mainStem, pfafVec  ; output
  
  ;if(iDangle eq 2)then stop, 'end of loop'

 endfor  ; looping through dangling reaches

 ; save Pfafstetter vector
 save, pfafVec, filename=pfafName

; restore Pfafstetter vector
endif else begin
 restore, pfafName
endelse

; *****
; * PUT THE DATA IN THE SHAPEFILES... 
; ***********************************

; Define shapefiles
nhdFiles = [$
            ['MS','10U'], $
            ['PN','17' ], $
            ['SA','03W'], $
            ['SA','03N'], $
            ['CO','14' ], $
            ['GB','16' ], $
            ['SR','09' ], $
            ['CA','18' ], $
            ['NE','01' ], $
            ['SA','03S'], $
            ['GL','04' ], $
            ['MS','05' ], $
            ['MS','06' ], $
            ['MS','07' ], $
            ['MS','08' ], $
            ['MS','10L'], $
            ['MS','11' ], $
            ['TX','12' ], $
            ['RG','13' ], $
            ['CO','15' ], $
            ['MA','02' ]  ]

; loop through shapefiles
for iRegion=0,n_elements(nhdFiles)/2-1 do begin

 ; define NHD string
 nhdString = nhdFiles[0,iRegion] + '_' + nhdFiles[1,iRegion]

 ; define shapefiles
 shpFile_orig = nhd_root + 'nhdPlus_SHPs_final/Flowline_' + nhdString + '.shp'
 shpFile_new  = nhd_root + 'nhdPlus_SHPs_coastDangle/Flowline_' + nhdString + '.shp'

 ; copy shapefiles
 if(file_test(shpFile_new) eq 0)then $
 spawn, 'ogr2ogr ' + shpFile_new + ' ' + shpFile_orig + ' 2> log.txt' ; copy initial shapefile to shp_fileNew

 ; get shapefile for an individual region
 get_attributes, shpFile_new, 'COMID', comId_sh

 ; get the match
 matchName = savePath + 'matchShape_coastDangle_' + nhdString + '.sav'
 if(file_test(matchName) eq 0)then begin
  print, 'Matching the file ', matchName
  match, segId_mizu, comID_sh, segId_mizu_ix, comID_sh_ix
  save, segId_mizu_ix, comID_sh_ix, filename=matchName
 endif else begin
  restore, matchName
 endelse

 ; write flag to define routed elements
 defineAttributes, shpFile_new, 'isRouted', 'integer', ixRouted ; ixRouted = column in the file
 writeAttributes, shpFile_new, ixRouted, comID_sh_ix, replicate(1, n_elements(comID_sh_ix))

 ; write Pfafstetter code
 defineAttributes, shpFile_new, 'pfafCode', 'character(30)', ixPfafCode ; ixPfafCode = column in the file
 writeAttributes, shpFile_new, ixPfafCode, comID_sh_ix, strtrim(pfafVec[segId_mizu_ix],2)
 print, shpFile_new, max(pfafVec[segId_mizu_ix])

endfor ; looping through regions

stop
end
