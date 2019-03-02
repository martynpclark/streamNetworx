pro assignOtherDangle

; Used to identify dangling reaches and write them to a conus shapefile

; get path to NHD-plus
nhd_root = '/Users/mac414/geospatial_data/NHD_Plus/ancillary_data/'

; define path for .sav files
savePath = nhd_root + 'idlSave/'

; define new shapefile
shapeFile_dangle = nhd_root + 'nhdPlus_SHPs_dangle/conusDangle.shp'

; define entity types
typePoly = 5 ; entityType=5 is a polygon
typeLine = 3 ; entityType=3 is a polyLine

; initialize shapefile index
jShape=0

; Define shapefiles
nhdFiles = [$
            ['SR','09' ], $
            ['PN','17' ], $
            ['SA','03N'], $
            ['MS','10U'], $
            ['CO','14' ], $
            ['GB','16' ], $
            ['CA','18' ], $
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
            ['MA','02' ]  ]

; get additional codes (1-level)
pLev1 = indgen(4)*2+2

; get additional codes (2-level)
pTemp = pLev1#replicate(1,4)
pLev2 = reform(transpose(pTemp*100) + pTemp, 16)

; get additional codes (3-level)
p100  = rebin(replicate(1,4)#pLev1, 4, 16, /sample)
p010  = rebin(reform(rebin(pLev1, 4, 4, /sample), 1, 16), 4, 16, /sample)
p001  = rebin(pLev1, 4, 16, /sample)
pLev3 = reform(p100*10000L + p010*100L + p001, 4*16)

; concatenate
pSuffix = strtrim([pLev1, pLev2, pLev3],2)
nSuffix = n_elements(pSuffix)
print, pSuffix
print, nSuffix

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
 shpFile_new  = nhd_root + 'nhdPlus_SHPs_allDangle/Flowline_'   + nhdString + '.shp'
 shpFile_orig = nhd_root + 'nhdPlus_SHPs_coastDangle/Flowline_' + nhdString + '.shp'
 shpFile_code = nhd_root + 'nhdPlus_SHPs_HDMA-HUC12/Catchment_' + nhdString + '.shp'
 print, shpFile_orig

 ; get the HDMA and HUC-12 codes
 get_attributes, shpFile_code, 'FEATUREID', featId_sh
 get_attributes, shpFile_code, 'HUC12',     huc12_sh
 get_attributes, shpFile_code, 'HDMA',      hdma_sh

 ; get the shapes
 get_attributes, shpFile_orig, 'COMID',    comId_sh
 get_attributes, shpFile_orig, 'pfafCode', pfafCode_seg

 ; get the number of shapes
 nShapes = n_elements(comId_sh)

 ; get zero-padded HUC-12
 ixMatch = where(strLen(huc12_sh) eq 11, nMatch)
 if(nMatch gt 0)then huc12_sh[ixMatch] = replicate('0',nMatch)+huc12_sh[ixMatch]

 ; get a new shapefile
 spawn, 'ogr2ogr ' + shpFile_new + ' ' + shpFile_orig + ' 2> log.txt' ; copy initial shapefile to shpFile_new

 ; *****
 ; * GET SUBSET OF REACHES IN A SPECIFIC REGION...
 ; ***********************************************
 
 ; define unique string for save files
 nameRegion = nhdFiles[0,iFile] + '_' + nhdFiles[1,iFile]

 ; match the netcdf seg id
 matchName = savePath + 'matchMizu_nhdPlusFinal_' + nameRegion + '.sav'
 if(file_test(matchName) eq 0)then begin
  print, 'Matching the file ' + matchName
  match, segId_mizu, comID_sh, segId_mizu_ix, comID_sh_ix
  save, segId_mizu_ix, comID_sh_ix, filename=matchName
 endif else begin
  restore, matchName
 endelse

 ; *****
 ; * GET THE MAPPING BETWEEN HRUS AND STREAM SEGMENTS...
 ; *****************************************************

 ; match the catchments with the segments
 matchName = savePath + 'matchFeature-Segment_' + nameRegion + '.sav'
 if(file_test(matchName) eq 0)then begin
  print, 'Matching the file ' + matchName
  match, comID_sh[comID_sh_ix], featId_sh, segment_ix, feature_ix
  save, segment_ix, feature_ix, filename=matchName
 endif else begin
  restore, matchName
 endelse

 ; define the index of the HRU associated with each segment
 nRegion   = n_elements(comID_sh_ix)
 ixSeg2hru = replicate(-9999L, nRegion)
 ixSeg2hru[segment_ix] = feature_ix

 ; define the Pfafstetter codes for the catchments
 pfafCode_hru = replicate(0LL, n_elements(featId_sh))
 pfafCode_hru[feature_ix] = long64(pfafCode_seg[comID_sh_ix[segment_ix]])

 ; test
 iStart=0L
 for iSeg=iStart,iStart+10 do begin
  if(ixSeg2hru[iSeg] ne -9999L)then print, 'test: id = ', ixSeg2hru[iSeg], comID_sh[comID_sh_ix[iSeg]], featId_sh[ixSeg2hru[iSeg]]
 endfor

 ; *****
 ; * IDENTIFY PFAFSTETTER CODES FOR DANGLING REACHES...
 ; ****************************************************

 ; define the maximum number of levels
 maxLevel = 19  ; cannot have numbers with more than 19 digits

 ; define the pfafstetter code
 mainStem = replicate(0L,  maxLevel,nSeg)
 pfafVec  = replicate(0LL, nSeg)

 ; define "dangling" reaches
 ixDangle = where(downSegId[segId_mizu_ix] le 0, nDangle)
 print, 'Processing ', nameRegion, '; nDangle = ', nDangle

 ; sort the dangling reaches by upstream area
 ixSort = reverse(sort(totalArea_mizu[segId_mizu_ix[ixDangle]]))

 ; check that we do not assign multiple dangling reaches the same starting value
 origCheck = strarr(nDangle)
 newCheck  = strarr(nDangle)

 ; loop through dangling reaches
 for iDangle=0,nDangle-1 do begin

  ; get indices to the shape file and the national database
  jDangle = ixDangle[ixSort[iDangle]]
  iShape  = comID_sh_ix[jDangle]
  iMizu   = segId_mizu_ix[jDangle]

  ; check
  if(comID_sh[iShape] ne segId_mizu[iMizu])then stop, 'mismatch in comID'
  if(downSegId[iMizu] gt 0)then stop, 'expect downSegId to be less than or equal to zero'

  ; get indices to the HDMA code
  jShape = ixSeg2hru[jDangle]
  if(jShape ne -9999)then begin
   huc12_target = strtrim(huc12_sh[jShape],2)
   hdma_target  = strtrim(hdma_sh[jShape],2)
   if(featId_sh[jShape] ne comID_sh[iShape])then stop, 'unexpected match between catchment and flowline'

  ; no mapping to the sub-basins
  endif else begin

   ; first check if there is no area
   if(totalArea_mizu[iMizu] lt 0.001d)then continue

   ; check
   print, 'nUpstream = ', upSeg_count[iMizu]
   stop, 'no mapping to sub-basins -- could be a zero-length connector reach and need to climb upstream'

  endelse ; no mapping to sub-basins

  ; initialize the Pfafstetter code
  strPfaf = '2000'  ; Pfaf=2 for North America is the Mackenzie, so '2000' provides a unique starting point for the conus
  nLevels = strlen(strPfaf)
  iLevel  = nLevels-1

  ; initialize the Pfafstetter code -- get pCode vector
  pCode = replicate(0L, maxLevel)
  for ix=0,nLevels-1 do pCode[ix] = strmid(strPfaf,ix,1)

  ; get the Pfafstetter codes
  danglePfafstetter, iLevel, iMizu, pCode, segId_mizu, upSeg_count, upsReach, totalArea_mizu, $  ; input
                     mainStem, pfafVec  ; output

  ; identify the upstream reaches
  ixSubset = where(strmid(strtrim(pfafVec[segId_mizu_ix],2),0,nLevels) eq strPfaf, nUpstream)
  if(nUpstream eq 0)then stop, 'expect some reaches upstream'
  pfafSubset = strtrim(pfafVec[segId_mizu_ix[ixSubset]], 2)

  ; identify the upstream catchments
  jxSubset = where(ixSeg2hru[ixSubset] ne -9999, nCatchments)
  if(nCatchments eq 0)then stop, 'expect some catchments upstream'

  ; get subsets
  kxSubset   = ixSeg2hru[ixSubset[jxSubset]]
  hucSubset  = strtrim(huc12_sh[kxSubset], 2)
  hdmaSubset = strtrim(hdma_sh[kxSubset], 2)

  ; check
     ;    for iUpstream=0,nUpstream-1 do begin
     ;     if(iUpstream mod 100 eq 0)then begin
     ;      jUpstream = ixSubset[iUpstream]
     ;      if(ixSeg2hru[jUpstream] ne -9999)then begin
     ;       kUpstream = ixSeg2hru[jUpstream]
     ;       print, iUpstream, comId_sh[comId_sh_ix[jUpstream]], featId_sh[kUpstream], ' : ', hdma_sh[kUpstream]
     ;      endif
     ;     endif
     ;    endfor

  ; loop through regions/sub-regions/basin/sub-basin/watershed/sub-watershed
  jClass = -9999
  for iClass=12,2,-2 do begin

   ; identify the most common code for the basin subset
   hucLevel = long64(strmid(hucSubset, 0, iClass))
   getMode, hucLevel, hucMode, nMode
   ;print, 'level, hucMode, nMode, nCatchments = ', iClass, hucMode, nMode, nCatchments

   ; check that the mode includes at least half of the catchments
   if(double(nMode)/double(nCatchments) gt 0.5d)then begin

    ; identify the matching HUC codes 
    iyMatch = where(long64(strmid(huc12_sh, 0, iClass)) eq hucMode, nMatch)
    if(nMatch eq 0)then stop, 'no match at a given HUC level'

    ; identify cases where the Pfafsttter code is assigned
    izMatch = where(pfafCode_hru[iyMatch] gt 0LL, nMatch)

   ; mode is < half of the catchments = heterogeneous
   endif else begin
    nMatch=0
   endelse

   ; check
   ;print, 'level, hucMode, nMode, nMatch, nCatchments, ratio = ', $
   ; iClass, hucMode, nMode, nMatch, nCatchments, double(nMode)/double(nCatchments), format='(a,1x,5(i12,1x),f9.3)'

   ; identify huc level where there are more catchments assigned than the area of the basin
   if(nMatch gt nCatchments)then begin
    jClass=iClass
    nAssigned=nMatch
    break
   endif 

  endfor  ; looping through classes

  ; check
  ;print, 'available level = ', jClass

  ; decide to use HDMA
  hdma_class = 4
  if(jClass le hdma_class)then begin 

   ; find the common HDMA code
   for iCode=1,11 do begin
    ixMatch = where(strmid(hdma_sh[kxSubset], iCode, 1) eq strmid(hdma_target, iCode, 1), nMatch)
    ;print, strmid(hdma_target, iCode, 1), nMatch, nCatchments, double(nMatch)/double(nCatchments)
    if(double(nMatch)/double(nCatchments) lt 0.5d)then begin
     jCode = iCode-1
     break
    endif
   endfor
   commonCode = strmid(hdma_target, 1, jCode)+'0'
   
  ; use HUC-12
  endif else begin

   ; get PfafCode as strings
   ixAssigned = iyMatch[izMatch]
   pfafString = strtrim(pfafCode_hru[ixAssigned],2)
   pfafLength = strlen(pfafString)
   maxLength  = max(pfafLength)

   ; pad previously assigned Pfafstetter codes with zeroes
   pfafPadded = strtrim(pfafCode_hru[ixAssigned]*10LL^(maxLength-pfafLength), 2)
   if(min(strlen(pfafPadded)) lt maxLength)then stop, 'unexpected string operations'

   ; find the common Pfafstetter code
   for nCode=1,maxLength do begin
    getMode, long64(strmid(pfafPadded, 0, nCode)), pfafMode, nMode
    ;print, 'pfafMode, nMode, nAssigned, ratio = ', pfafMode, nMode, nAssigned, double(nMode)/double(nAssigned)
    if(double(nMode)/double(nAssigned) lt 0.75d)then begin
     jCode = nCode-1
     break
    endif
   endfor
   if(jCode eq 0)then stop, 'expect some Pfafstetter codes are assigned in the same region'
   commonCode = strmid(strtrim(pfafMode,2), 0, jCode)+'0'
   
  endelse

  ; save the original code
  origCheck[iDangle] = commonCode

  ; ensure that we do not have duplicate codes
  if(iDangle gt 0)then begin

   ; get the current count of common codes
   ixCheck = where(origCheck[0:iDangle-1] eq commonCode, nCheck)
   if(nCheck gt nSuffix)then stop, 'need more suffixes'

   ; update the common code
   if(nCheck gt 0)then commonCode = commonCode + pSuffix[nCheck-1]

   ; check updated codes
   ixCheck = where(newCheck[0:iDangle-1] eq commonCode, nCheck)
   if(nCheck gt 0)then stop, 'unexpected duplicate code'

  endif ; if iDangle>0

  ; update codes
  newCheck[iDangle] = commonCode
  print, 'commonCode = ', iDangle, ' : ', commonCode

  ; replace the initial string with the common code
  tempCode = commonCode+strmid(pfafSubset,nLevels)
  pfafVec[segId_mizu_ix[ixSubset]]    = long64(tempCode)
  pfafCode_seg[comID_sh_ix[ixSubset]] = tempCode

  ; update the HRU Pfafstetter code
  pfafCode_hru[feature_ix] = long64(pfafCode_seg[comID_sh_ix[segment_ix]])

  ; write the new attributes
  defineAttributes, shpFile_new, 'pfafCode',  'notUsed', ixPfafCode       ; ixPfafCode  = column in the file
  writeAttributes,  shpFile_new, ixPfafCode, comID_sh_ix[ixSubset], pfafCode_seg[comID_sh_ix[ixSubset]]

  ;stop

 endfor  ; looping through dangling reaches

 stop

endfor  ; looping through regions


stop
end

pro getMode, array, mode, maxfreq

   ; Calculates the MODE (value with the maximum frequency distribution)
   ; of an array. Works ONLY with integer data.

   ; Check for arguments.
   IF N_Elements(array) EQ 0 THEN Message, 'Must pass an array argument.'
  
   ; get unique values
   ixSort = sort(array)
   ixUniq = uniq(array[ixSort])
   nUniq  = n_elements(ixUniq) 

   ; special case of 1 category
   if(nUniq eq 1)then begin
    valFreq = array[ixSort[ixUniq]]
    maxFreq = n_elements(array)
    mode    = valFreq[0]
  
   ; standard case
   endif else begin
    nFreq   = [ixUniq[0]+1, ixUniq[1:nUniq-1]-ixUniq[0:nUniq-2]]
    maxFreq = max(nFreq, ixFreq) ; gets the first element if tied first place
    valFreq = array[ixSort[ixUniq]]
    mode    = valFreq[ixFreq]
   endelse

   ; check
   ;iVoid = where(array eq mode, nVoid)
   ;if(nVoid ne maxFreq)then stop, 'mismatch in mode'
   
END


