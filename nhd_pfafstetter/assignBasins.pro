pro assignBasins

; used to assign Pfafstetter codes to basins 

; get path to NHD-plus
nhd_root = '/Users/mac414/geospatial_data/NHD_Plus/ancillary_data/'

; define path for .sav files
savePath = nhd_root + 'idlSave/'

; define entity types
typePoly = 5 ; entityType=5 is a polygon
typeLine = 3 ; entityType=3 is a polyLine

; initialize shapefile index
jShape=0

; Define shapefiles
nhdFiles = [$
            ['CO','14' ], $
            ['CO','15' ], $
            ['GB','16' ], $
            ['CA','18' ], $
            ['PN','17' ], $
            ['RG','13' ], $
            ['SR','09' ], $
            ['SA','03N'], $
            ['NE','01' ], $
            ['MA','02' ], $
            ['SA','03W'], $
            ['SA','03S'], $
            ['GL','04' ], $
            ['MS','05' ], $
            ['MS','06' ], $
            ['MS','07' ], $
            ['MS','08' ], $
            ['MS','10U'], $
            ['MS','10L'], $
            ['MS','11' ], $
            ['TX','12' ], $
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
pSuffix = '000'+strtrim([pLev1, pLev2, pLev3],2)
nSuffix = n_elements(pSuffix)
;print, pSuffix
;print, nSuffix
;stop

; *****
; * READ THE NHD+ TOPOLOGY...
; ***************************

; define the NetCDF file
nc_filename = nhd_root + 'NHDPlus2_updated-CONUS.nc'
print, 'Reading ancillary file'

; open file
nc_file = ncdf_open(nc_filename, /nowrite)

 ; get the basin id
 ivar_id = ncdf_varid(nc_file,'idFeature')
 ncdf_varget, nc_file, ivar_id, hruId_mizu

 ; get the unique id of the stream segment below each HRU
 ivar_id = ncdf_varid(nc_file,'hru2seg')
 ncdf_varget, nc_file, ivar_id, hru2seg_mizu

 ; get the index of the stream segment below each HRU
 ivar_id = ncdf_varid(nc_file,'hruSegIndex')
 ncdf_varget, nc_file, ivar_id, hruSegIndex_mizu

 ; get the segid
 ivar_id = ncdf_varid(nc_file,'link')
 ncdf_varget, nc_file, ivar_id, segId_mizu

 ; get the unique id of the next downstream segment
 ivar_id = ncdf_varid(nc_file,'to')
 ncdf_varget, nc_file, ivar_id, downSegId

 ; get the total area
 ivar_id = ncdf_varid(nc_file,'totalArea')
 ncdf_varget, nc_file, ivar_id, totalArea_mizu

; close file
ncdf_close, nc_file

; get the number of segments and HRUs
nHRU = n_elements(hruId_mizu)
nSeg = n_elements(segId_mizu)

; identify the HRUs that drain to segments
ixMatch = where(hruSegIndex_mizu gt 0, nMatch)
if(nMatch eq 0)then stop, 'expect at least some valid indices'
 
; define the index of the HRU associated with each segment
ixSeg2hru = replicate(-9999L, nSeg)
ixSeg2hru[hruSegIndex_mizu[ixMatch]-1] = ixMatch ; -1 to convert to zero-based indexing

; test
iStart=4347L
for iSeg=iStart,iStart+10 do begin
 if(ixSeg2hru[iSeg] ne -9999L)then print, 'test: id = ', ixSeg2hru[iSeg], hruId_mizu[ixSeg2hru[iSeg]], segId_mizu[iSeg]
endfor

; *****
; * READ THE COASTAL SHAPEFILE...
; *******************************

; define the NetCDF file
shpFile_coast = nhd_root + 'nhdPlus_SHPs_coast/conusCoast_pfaf-all.shp'

; get the attributes
get_attributes, shpFile_coast, 'idUnique',  idCoast
get_attributes, shpFile_coast, 'pfafCode',  pfafCode_coast
get_attributes, shpFile_coast, 'coastMask', coastMask

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
 shpFile_code  = nhd_root + 'nhdPlus_SHPs_HDMA-HUC12/Catchment_' + nhdString + '.shp'
 shpFile_seg   = nhd_root + 'nhdPlus_SHPs_noDuplicate/Flowline_' + nhdString + '.shp'
 shpFile_new   = nhd_root + 'nhdPlus_SHPs_noDuplicate/Catchment_' + nhdString + '.shp'

 ; get the HDMA and HUC-12 codes
 print, 'Reading HDMA and HUC-12 codes'
 get_attributes, shpFile_code, 'FEATUREID', featId_sh
 get_attributes, shpFile_code, 'HUC12',     huc12_sh
 get_attributes, shpFile_code, 'HDMA',      hdma_sh

 ; get the segment pfafCodes
 print, 'Reading segment pfafCodes'
 get_attributes, shpFile_seg, 'COMID',    comId_sh
 get_attributes, shpFile_seg, 'pfafCode', pfafCode_string
 pfafCode_seg = long64(pfafCode_string)

 ; get the number of shapes
 nShapes = n_elements(comId_sh)

 ; get zero-padded HUC-12
 ixMatch = where(strLen(huc12_sh) eq 11, nMatch)
 if(nMatch gt 0)then huc12_sh[ixMatch] = replicate('0',nMatch)+huc12_sh[ixMatch]

 ; get a new shapefile
 if(file_test(shpFile_new) eq 0)then begin
  print, 'Making '+shpFile_new
  spawn, 'ogr2ogr ' + shpFile_new + ' ' + shpFile_code + ' 2> log.txt' ; copy initial shapefile to shpFile_new
 endif

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

 ; match the netcdf hru id
 matchName = savePath + 'matchMizu_catchments_' + nameRegion + '.sav'
 if(file_test(matchName) eq 0)then begin
  print, 'Matching the file ' + matchName
  match, hruId_mizu, featId_sh, hruId_mizu_ix, featID_sh_ix
  save, hruId_mizu_ix, featID_sh_ix, filename=matchName
 endif else begin
  restore, matchName
 endelse

 ; put the data in the full vector
 hruIndex = replicate(-9999L, nHRU)
 hruIndex[hruId_mizu_ix] = featID_sh_ix

 ; match the coastal segments
 matchName = savePath + 'matchRegion_coastal_' + nameRegion + '.sav'
 if(file_test(matchName) eq 0)then begin
  print, 'Matching the file ' + matchName
  match, idCoast, featId_sh, idCoast_ix, coastMap_ix
  save, idCoast_ix, coastMap_ix, filename=matchName
 endif else begin
  restore, matchName
 endelse

 ; *****
 ; * GET THE MAPPING BETWEEN HRUS AND STREAM SEGMENTS...
 ; *****************************************************

 print, 'Get mapping between basins and stream segments'

 ; identify number of segments in the region, and number of basins
 nRegion = n_elements(comID_sh)
 nBasins = n_elements(featId_sh)

 ; identify valid global segment-hru mapping
 ixValid = where(ixSeg2hru[segId_mizu_ix] ge 0, nValid)
 if(nValid eq 0)then stop, 'expect some valid global segment-hru mapping'

 ; define region mapping
 ixMapping = hruIndex[ixSeg2hru[segId_mizu_ix[ixValid]]]
 if(min(ixMapping) lt 0)then stop, 'invalid mapping indices'

 ; define the ixSeg2hru local
 ixSeg2hru_local = replicate(-9999L, nRegion)
 ixSeg2hru_local[comID_sh_ix[ixValid]] = ixMapping

 ; test
 iStart=259L
 for iSeg=iStart,iStart+10 do begin
  if(ixSeg2hru_local[iSeg] ne -9999L)then print, 'test: id = ', ixSeg2hru_local[iSeg], comID_sh[iSeg], featId_sh[ixSeg2hru_local[iSeg]]
 endfor

 ; identify valid local segment-hru mapping
 ixValid = where(ixSeg2hru_local ge 0, nValid)
 if(nValid eq 0)then stop, 'expect some valid local segment-hru mapping'

 ; define the Pfafstetter codes for the catchments
 pfafCode_hru = replicate(0LL, nBasins)
 pfafCode_hru[ixSeg2hru_local[ixValid]] = pfafCode_seg[ixValid]

 ; check that all segments are assigned
 ixMatch = where(pfafCode_seg[comID_sh_ix] eq 0LL, nMatch)
 if(nMatch gt 0)then begin
  if(max(totalArea_mizu[segId_mizu_ix[ixMatch]]) gt 0.1d)then stop, 'have not assigned pfaf codes to all stream segments'
 endif

 ; *****
 ; * ASSIGN CODES TO UNASSIGNED COASTAL BASINS...
 ; **********************************************

 print, 'Assigning Pfafstetter codes to coastal basins'

 ; check that there are some coastal basins
 if(min(coastMap_ix) ge 0)then begin

  ; identify the coastal basins that are not assigned
  ixMatch = where(pfafCode_hru[coastMap_ix] eq 0LL and coastMask[idCoast_ix] eq 0, nMatch)
  if(nMatch gt 0)then begin ;  unassigned basins
  
   ; loop through unassigned basins
   for iBasin=0,nMatch-1 do begin
  
    ; get indices
    jShape = coastMap_ix[ixMatch[iBasin]]
    jCoast = idCoast_ix[ixMatch[iBasin]]
    if(featId_sh[jShape] ne idCoast[jCoast])then stop, 'id mismatch'
    if(coastMask[jCoast] ne 0)then stop, 'expect the coastal mask to be zero'
    if(pfafCode_hru[jShape] ne 0)then stop, 'expect the basin to be unassigned'

    ; save Pfafsteter code
    pfafCode_hru[jShape] = long64(pfafCode_coast[jCoast])
    ;print, iBasin, nMatch, ': ', pfafCode_coast[jCoast], ': ', featId_sh[jShape], ': ', huc12_sh[jShape], ': ', hdma_sh[jShape]
  
   endfor  ; looping through unassigned coastal basins
  
  endif  ; if unassigned coastal basins
 endif  ; if coastal basins exist
  
 ; *****
 ; * ASSIGN CODES TO UNASSIGNED ENDORHEIC BASINS...
 ; ************************************************

 ; define IDL save file
 saveFile = savePath + 'assignEndorheic_' + nameRegion + '.sav'
 if(file_test(saveFile) eq 0)then begin

  ; identify the endorheic basins that are not assigned
  ixMatch = where(pfafCode_hru eq 0LL, nMatch)
  if(nMatch gt 0)then begin ;  unassigned basins
  
   ; loop through unassigned basins
   for iBasin=0,nMatch-1 do begin
  
    ; get indices
    jShape = ixMatch[iBasin]
    if(pfafCode_hru[jShape] ne 0)then stop, 'expect the HRU to be unassigned'
    ;print, iBasin, nMatch, ': ', featId_sh[jShape], ': ', huc12_sh[jShape], ': ', hdma_sh[jShape]
  
    ; find the huc level that both contains a "sufficient number" of previously assigned reaches
    ;       (here a "sufficient number" is 10)
  
    ; define the "sufficient number"
    nDesire=10
  
    ; define the coarsest huc12
    bigHUC   = 6
    ixSubset = where(strmid(huc12_sh, 0, bigHUC) eq strmid(huc12_sh[jShape], 0, bigHUC), nSubset)
  
    ; if not in the big HUC then default to all assigned reaches
    ; NOTE: very rare
    if(nSubset lt nDesire)then begin
     jxAssigned = where(pfafCode_hru gt 0, nAssigned)
     getMode, strmid(strtrim(pfafCode_hru[ixAssigned],2),0,1), mode, maxfreq
     commonCode = mode+'0000'

    ; in the big HUC
    endif else begin

     nAssigned = 0
     ; loop through regions/sub-regions/basin/sub-basin/watershed/sub-watershed
     for iClass=12,bigHUC,-2 do begin
   
      ; get the smaller subset
      jxSubset = where(strmid(huc12_sh[ixSubset], 0, iClass) eq strmid(huc12_sh[jShape], 0, iClass), nSubset)
      if(nSubset ge nDesire)then begin
   
       ; identify the basins already assigned
       ixAssigned = where(pfafCode_hru[ixSubset[jxSubset]] ne 0LL, nAssigned)
       if(nAssigned ge nDesire)then begin
        jxAssigned = ixSubset[jxSubset[ixAssigned]]
        break
       endif  ; if the number of assigned basins is insufficient
   
      endif  ; if the subset is insufficient
   
     endfor  ; looping through HUC classes

     ; check
     if(nAssigned lt nDesire)then stop, 'cannot identify desired reaches'

     ; pad previously assigned Pfafstetter codes with zeroes
     pfafString = strtrim(pfafCode_hru[jxAssigned],2)
     pfafLength = strlen(pfafString)
     maxLength  = max(pfafLength)
     pfafPadded = strtrim(long64(pfafCode_hru[jxAssigned])*10LL^(maxLength-pfafLength), 2)
     if(min(strlen(pfafPadded)) lt maxLength)then stop, 'unexpected string operations'
     ;print, 'pfafPadded = ', pfafPadded
   
     ; identify the number of digits for the common code
     for iDigit=0,maxLength-1 do begin
      getMode, strmid(pfafPadded,iDigit,1), mode, maxfreq
      if(maxFreq lt nDesire)then begin
       nDigits=iDigit
       break
      endif
      if(iDigit eq maxLength-1)then nDigits=maxLength
     endfor
     if(nDigits eq 0)then stop, 'cannot find common code'
  
     ; get the common code
     getMode, strmid(pfafPadded,0,nDigits), commonTemp, maxfreq
   
     ; identify trailing zeroes
     strLength  = strlen(commonTemp)
     stringVec  = strarr(strLength)
     reads, commonTemp, stringVec, format='('+strtrim(strLength,2)+'(a1))'
     ixNoZero = stregex(strjoin(reverse(stringVec)),'[1-9]')
   
     ; get the common code (remove trailing zeroes)
     commonCode = strmid(commonTemp, 0, strLength-ixNoZero) + '0' ; a zero to denote basin is disconnected
     if(strlen(commonCode) le 4)then commonCode = commonCode + '000' ; emphasize isolated HRUs 

    endelse  ; in the big HUC

    ; add to the vector
    pfafCode_hru[jShape] = long64(commonCode)
    print, 'common code = ', iBasin, nMatch, ': ', commonCode
  
   endfor  ; looping through unassigned endorheic basins
  
  endif  ; if unassigned basins
  
  ; get the string
  pfafString_hru = strtrim(pfafCode_hru, 2)
  
  ; check
  maxLength = max(strlen(pfafString_hru),iMax)
  print, 'maximum string length = ', maxLength, iMax

  ; save
  save, pfafCode_hru, pfafString_hru, file=saveFile

 ; restore
 endif else begin
  restore, saveFile
 endelse

 ; *****
 ; * REMOVE DUPLICATE CODES... 
 ; ***************************

 ; get additional codes (1-level)
 pLev1 = indgen(9) +1
 nCode = n_elements(pLev1)

 ; get additional codes (2-level)
 pTemp = pLev1#replicate(1,nCode)
 pLev2 = reform(transpose(pTemp*10) + pTemp, nCode*nCode)

 ; get additional codes (3-level)
 p100  = rebin(replicate(1,nCode)#pLev1, nCode, nCode*nCode, /sample)
 p010  = rebin(reform(rebin(pLev1, nCode, nCode, /sample), 1, nCode*nCode), nCode, nCode*nCode, /sample)
 p001  = rebin(pLev1, nCode, nCode*nCode, /sample)
 pLev3 = reform(p100*100L + p010*10L + p001, nCode*nCode*nCode)

 ; get unique elements
 print, nameRegion, ': Getting unique elements'
 ixSort = sort(pfafCode_hru)
 ixUniq = uniq(pfafCode_hru[ixSort])
 nUniq  = n_elements(ixUniq)

 ; loop through unique elements
 print, 'Processing duplicates: ', nhdString

 oldUniq=0
 for iUniq=0,nUniq-1 do begin

  ; check that duplicates exist
  if(oldUniq lt ixUniq[iUniq])then begin

   ; get indices of the duplicates
   ixDuplicate = ixSort[oldUniq:ixUniq[iUniq]]
   pfafSubset  = long64(pfafCode_hru[ixDuplicate])
   nSubset     = n_elements(pfafSubset)

   ; check that they are duplicates
   if(min(pfafSubset) ne max(pfafSubset))then stop, 'expect duplicates'
   ;print, pfafString_hru[ixDuplicate]
   ;print, iUniq, nUniq, pfafSubset[0]

   ; define the pfafstetter code
   if(nSubset gt nCode*nCode*nCode)then stop, 'too many duplicate reaches'
   if(nSubset le nCode*nCode*nCode)then pSuffix = pLev3
   if(nSubset le nCode*nCode)      then pSuffix = pLev2
   if(nSubset le nCode)            then pSuffix = pLev1

   ; assign duplicates
   pfafString_hru[ixDuplicate] = pfafString_hru[ixDuplicate] + strtrim(pSuffix[0:nSubset-1],2)
   ;print, pfafString_hru[ixDuplicate]

   ;stop

  endif  ; if duplicates exist

  ; update oldUniq
  oldUniq = ixUniq[iUniq]+1

 endfor  ; looping through unique elements

 ; check
 maxLength = max(strlen(pfafString_hru),iMax)
 print, 'maximum string length (after duplicates) = ', maxLength, iMax

 if(strtrim(long64(pfafString_hru[iMax]),2) ne strtrim(pfafString_hru[iMax],2))then begin
  print, 'SERIOUS PROBLEM: string is too big '+strtrim(pfafString_hru[iMax],2)
  stop
 endif

 ; write the new attributes
 print, 'Writing duplicates: ', nhdString
 defineAttributes, shpFile_new, 'pfafCode', 'character(30)', ixPfafCode       ; ixPfafCode  = column in the file
 writeAttributes,  shpFile_new, ixPfafCode, featId_sh_ix, pfafString_hru[featId_sh_ix]

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


