pro assignDuplicate

; Used to identify duplicate reaches and write them to a conus shapefile

; get path to NHD-plus
nhd_root = '/Users/mac414/geospatial_data/NHD_Plus/ancillary_data/'

; define path for .sav files
savePath = nhd_root + 'idlSave/'

; Define shapefiles
nhdFiles = [$
            ['PN','17' ], $
            ['CA','18' ], $
            ['GB','16' ], $
            ['SR','09' ], $
            ['SA','03N'], $
            ['CO','14' ], $
            ['NE','01' ], $
            ['MA','02' ], $
            ['SA','03W'], $
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
            ['MS','10U'], $
            ['MA','02' ]  ]

; get additional codes (1-level)
pLev1 = indgen(9)+1
nCode = n_elements(pLev1)

; get additional codes (2-level)
pTemp = pLev1#replicate(1,nCode)
pLev2 = reform(transpose(pTemp*100) + pTemp, nCode*nCode)

; get additional codes (3-level)
p100  = rebin(replicate(1,nCode)#pLev1, nCode, nCode*nCode, /sample)
p010  = rebin(reform(rebin(pLev1, nCode, nCode, /sample), 1, nCode*nCode), nCode, nCode*nCode, /sample)
p001  = rebin(pLev1, nCode, nCode*nCode, /sample)
pLev3 = reform(p100*10000L + p010*100L + p001, nCode*nCode*nCode)

; concatenate
pSuffix = '00'+strtrim([pLev1, pLev2, pLev3],2)
nSuffix = n_elements(pSuffix)
;print, pSuffix
;print, nSuffix
;stop

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

 ; get the index of the next downstream segment
 ivar_id = ncdf_varid(nc_file,'downSegIndex')
 ncdf_varget, nc_file, ivar_id, downSegIndex

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
nSeg = n_elements(segId_mizu)
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

; ----------------------------------------------------------------------------------------------------------
; ----------------------------------------------------------------------------------------------------------
; ----------------------------------------------------------------------------------------------------------
; ----------------------------------------------------------------------------------------------------------
; ----------------------------------------------------------------------------------------------------------
; ----------------------------------------------------------------------------------------------------------

; loop through shapefiles
for iFile=0,n_elements(nhdFiles)/2-1 do begin

 ; *****
 ; * GET INFORMATION FROM THE SHAPEFILES...
 ; ****************************************

 ; define NHD string
 nhdString = nhdFiles[0,iFile] + '_' + nhdFiles[1,iFile]

 ; define shapefiles
 shpFile_new  = nhd_root + 'nhdPlus_SHPs_noDuplicate/Flowline_' + nhdString + '.shp'
 shpFile_orig = nhd_root + 'nhdPlus_SHPs_allDangle/Flowline_'   + nhdString + '.shp'

 ; get the Pfafstetter codes
 print, 'Reading shapefile attributes'
 get_attributes, shpFile_orig, 'COMID',    comId_sh
 get_attributes, shpFile_orig, 'pfafCode', pfafCode_seg

 ; get the number of shapes
 nShapes = n_elements(comId_sh)

 ; get a new shapefile
 print, 'Creating new shapefile ' + shpFile_new
 spawn, 'ogr2ogr ' + shpFile_new + ' ' + shpFile_orig + ' 2> log.txt' ; copy initial shapefile to shpFile_new

 ; *****
 ; * GET SUBSET OF REACHES IN A SPECIFIC REGION...
 ; ***********************************************
 
 ; define unique string for save files
 nameRegion = nhdFiles[0,iFile] + '_' + nhdFiles[1,iFile]

 ; match the netcdf seg id
 matchName = savePath + 'matchMizu_checkDuplicates_' + nameRegion + '.sav'
 if(file_test(matchName) eq 0)then begin
  print, 'Matching the file ' + matchName
  match, segId_mizu, comID_sh, segId_mizu_ix, comID_sh_ix
  save, segId_mizu_ix, comID_sh_ix, filename=matchName
 endif else begin
  restore, matchName
 endelse

 ; get additional codes (1-level)
 pLev1 = indgen(5)*2 +1
 nCode = n_elements(pLev1)

 ; get additional codes (2-level)
 pTemp = pLev1#replicate(1,nCode)
 pLev2 = reform(transpose(pTemp*10) + pTemp, nCode*nCode)

 ; get additional codes (3-level)
 p100  = rebin(replicate(1,nCode)#pLev1, nCode, nCode*nCode, /sample)
 p010  = rebin(reform(rebin(pLev1, nCode, nCode, /sample), 1, nCode*nCode), nCode, nCode*nCode, /sample)
 p001  = rebin(pLev1, nCode, nCode*nCode, /sample)
 pLev3 = reform(p100*100L + p010*10L + p001, nCode*nCode*nCode)

 ; get the Pfafstetter codes for the full network
 nMizu = n_elements(downSegIndex)
 pfafCode_mizu = replicate('-9999', nMizu)
 pfafCode_mizu[segId_mizu_ix] = pfafCode_seg[comID_sh_ix]

 ; get unique elements
 print, nameRegion, ': Getting unique elements'
 ixSort = sort(pfafCode_seg[comID_sh_ix])
 ixUniq = uniq(pfafCode_seg[comID_sh_ix[ixSort]])
 nUniq  = n_elements(ixUniq)

 ; loop through unique elements
 print, 'Processing duplicates: ', nhdString

 oldUniq=0
 for iUniq=0,nUniq-1 do begin

  ; check that duplicates exist
  if(oldUniq lt ixUniq[iUniq])then begin

   ; get indices of the duplicates
   ixDuplicate = ixSort[oldUniq:ixUniq[iUniq]]
   pfafSubset  = long64(pfafCode_seg[comID_sh_ix[ixDuplicate]])
   nSubset     = n_elements(pfafSubset)

   ; check that they are duplicates
   if(min(pfafSubset) ne max(pfafSubset))then stop, 'expect duplicates'
   ;print, segId_mizu[segId_mizu_ix[ixDuplicate]]
   ;print, pfafSubset

   ; check that the Pfafstetter code is not zero
   if(min(pfafSubset) gt 0)then begin

    ; get the most downstream reach
    ixDown   = downSegIndex[segId_mizu_ix[ixDuplicate]]-1 ; -1 to convert to zero-based indexing
    ixDesire = where(long64(pfafCode_mizu[ixDown]) ne min(pfafSubset), nDesire)
    if(nDesire ne 1)then stop, 'expect one mismatch'
    jxDesire = ixDuplicate[ixDesire[0]]

    ; define the pfafstetter code
    if(nSubset gt nCode*nCode*nCode)then stop, 'too many duplicate reaches'
    if(nSubset le nCode*nCode*nCode)then pSuffix = pLev3
    if(nSubset le nCode*nCode)      then pSuffix = pLev2
    if(nSubset le nCode)            then pSuffix = pLev1

    ; crawl upstream
    for iSeg=0,nSubset-1 do begin

     ; update Pfafsttter code
     jMizu  = segId_mizu_ix[jxDesire]
     jShape = comID_sh_ix[jxDesire]
     if(segId_mizu[jMizu] ne comID_sh[jShape])then stop, 'mismatch ids'
     pfafCode_seg[jShape] = pfafCode_seg[jShape] + strtrim(pSuffix[iSeg],2)
     ;print, pfafCode_seg[jShape], segId_mizu[jMizu]

     ; get the upstream reach
     jxDesire = -9999
     if(iSeg lt nSubset-1)then begin
      for iUps=0,upSeg_count[jMizu]-1 do begin
       desireId = (*(upsReach[jMizu])).upSegIds[iUps]
       ixDesire = where(segId_mizu[segId_mizu_ix[ixDuplicate]] eq desireId, nDesire)
       if(nDesire ne 1)then continue
       jxDesire = ixDuplicate[ixDesire[0]]
      endfor
      if(jxDesire eq -9999)then stop, 'could not find upstream reach'
     endif

    endfor  ; crawling upstream

    ; check
    ;if(nSubset gt 10)then stop

   endif   ; if the code is not zero 
  endif   ; if duplicates exist

  ; increment the index
  oldUniq = ixUniq[iUniq]+1

 endfor  ; looping through unique elements

 ; write the new attributes
 print, 'Writing duplicates: ', nhdString
 defineAttributes, shpFile_new, 'pfafCode',  'notUsed', ixPfafCode       ; ixPfafCode  = column in the file
 writeAttributes,  shpFile_new, ixPfafCode, comID_sh_ix, pfafCode_seg[comID_sh_ix]

endfor  ; looping through regions


stop
end
