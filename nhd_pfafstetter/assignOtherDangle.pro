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
            ['CA','18' ], $
            ['RG','13' ], $
            ['GB','16' ], $
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
            ['CO','14' ], $
            ['CO','15' ], $
            ['PN','17' ], $
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
pSuffix = '00'+strtrim([pLev1, pLev2, pLev3],2)
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
 ;iStart=0L
 ;for iSeg=iStart,iStart+10 do begin
 ; if(ixSeg2hru[iSeg] ne -9999L)then print, 'test: id = ', ixSeg2hru[iSeg], comID_sh[comID_sh_ix[iSeg]], featId_sh[ixSeg2hru[iSeg]]
 ;endfor

 ; =====================================================================================
 ; =====================================================================================
 ; =====================================================================================
 ; =====================================================================================
 ; =====================================================================================
 ; =====================================================================================

 ; *****
 ; * IDENTIFY PFAFSTETTER CODES FOR DANGLING REACHES...
 ; ****************************************************

 ; define the maximum number of levels
 maxLevel  = 19  ; cannot have numbers with more than 19 digits

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

 ; save the length of the Pfafstetter code
 codeLength = intarr(nDangle)

 ; loop through dangling reaches
 for iDangle=0,nDangle-1 do begin

  ; *****
  ; * GET INITIAL INDICES...
  ; ************************

  ; get indices to the shape file and the national database
  jDangle = ixDangle[ixSort[iDangle]]
  iShape  = comID_sh_ix[jDangle]
  iMizu   = segId_mizu_ix[jDangle]

  ; avoid segments that are already processed
  if(long64(pfafCode_seg[iShape]) gt 0)then continue

  ; avoid segments with zero area
  if(totalArea_mizu[iMizu] lt 0.001d)then continue

  ; check
  if(comID_sh[iShape] ne segId_mizu[iMizu])then stop, 'mismatch in comID'
  if(downSegId[iMizu] gt 0)then stop, 'expect downSegId to be less than or equal to zero'

  ; *****
  ; * COMPUTE PFAFSTETTER CODES FOR DANGLING REACHES...
  ; ***************************************************

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

  ; *****
  ; * GET INDICES FOR THE UPSTREAM SEGMENTS/CATCHMENTS...
  ; *****************************************************

  ; get the total number of upstream catchments
  ixTotal = where(strmid(strtrim(pfafVec,2),0,nLevels) eq strPfaf, nTotal)

  ; identify the upstream reaches
  ixSubset = where(strmid(strtrim(pfafVec[segId_mizu_ix],2),0,nLevels) eq strPfaf, nUpstream)
  if(nUpstream eq 0)then stop, 'expect some reaches upstream'
  if(nUpstream ne nTotal)then stop, 'fatal error: basin crosses regional boundaries'
  pfafSubset = strtrim(pfafVec[segId_mizu_ix[ixSubset]], 2)

  ; identify the upstream catchments
  jxSubset = where(ixSeg2hru[ixSubset] ne -9999, nCatchments)
  if(nCatchments eq 0)then stop, 'expect some catchments upstream'

  ; get subsets
  kxSubset   = ixSeg2hru[ixSubset[jxSubset]]
  hucSubset  = strtrim(huc12_sh[kxSubset], 2)
  hdmaSubset = strtrim(hdma_sh[kxSubset], 2)

  ; get the maximum length of pfafSubset
  pfafLength  = strlen(pfafSubset)
  maxUpstream = max(pfafLength)-nLevels

  ; *****
  ; * IDENTIFY THE HUC LEVEL THAT CONTAINS A SUFFICIENT NUMBER OF PREVIOUSLY ASSIGNED REACHES...
  ; ********************************************************************************************

  ; find the huc level that both
  ; (1) contains a high frequency of reaches upstream of the dangling reach; and
  ; (2) contains a sufficient number of previously assigned reaches
  ;       (defined as more previously assigned reaches than the number of upstream reaches)

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
   print, 'level, hucMode, nMode, nMatch, nCatchments, ratio = ', $
    iClass, hucMode, nMode, nMatch, nCatchments, double(nMode)/double(nCatchments), format='(a,1x,5(i12,1x),f9.3)'

   ; identify huc level where there are more catchments assigned than the number of catchments considered
   if(nMatch gt nCatchments)then begin
    jClass=iClass
    nAssigned=nMatch
    break
   endif 

  endfor  ; looping through classes

  ; force match previously assigned Pfaf in the same HUC if HDMA is incorrect
  getMode, long64(strmid(hdma_sh[kxSubset], 1, 1)), pfafMode, nMode
  if(pfafMode ne 0 and  nhdFiles[1,iFile] eq 16)then forceHUC=1 else forceHUC=0

  ; check
  print, 'available level, forceHUC = ', jClass, forceHUC

  ; *****
  ; * IDENTIFY COMMON HDMA CODE...
  ; ******************************

  ; define threshold to use hdma
  if(nhdString eq 'SR_09' or nhdString eq 'GB_16')then hdma_class=6 else hdma_class = 0

  ; decide to use HDMA
  if(jClass le hdma_class and forceHUC eq 0)then begin 

   ; identify define mode
   defineMode='hdma'

   ; find the common HDMA code
   jCode=11 ; initialize jCode
   for nCode=1,12 do begin
    getMode, long64(strmid(hdma_sh[kxSubset], 0, nCode)), pfafMode, nMode
    print, 'hdma: pfafMode, nMode, nCatchments, ratio = ', pfafMode, nMode, nCatchments, double(nMode)/double(nCatchments)
    if(double(nMode)/double(nCatchments) lt 0.5d)then begin
     jCode = nCode-1
     break
    endif
   endfor

   ; get the Pfafstetter string (jcode-1 because we remove the continental identfier)
   pfafString = strmid(strtrim(pfafMode,2), 1, jCode-1)

   ; deal with special case of the Great Basin -- want a leading "9" so can treat as an integer
   if(nhdString eq 'GB_16')then pfafString='9'+pfafString  ; need to check that no '90*' are in California

  ; *****
  ; * IDENTIFY COMMON PFAFSTETTER CODE FROM PREVIOUSLY ASSIGNED REACHES...
  ; **********************************************************************

  ; use HUC-12
  endif else begin

   ; identify define mode
   defineMode='huc12'

   ; get PfafCode as strings
   ixAssigned = iyMatch[izMatch]
   pfafString = strtrim(pfafCode_hru[ixAssigned],2)
   pfafLength = strlen(pfafString)
   maxLength  = max(pfafLength)

   ; pad previously assigned Pfafstetter codes with zeroes
   pfafPadded = strtrim(pfafCode_hru[ixAssigned]*10LL^(maxLength-pfafLength), 2)
   if(min(strlen(pfafPadded)) lt maxLength)then stop, 'unexpected string operations'

   ; find the common previously assigned Pfafstetter code
   jCode=maxLength ; initialize jCode
   for nCode=1,maxLength do begin
    getMode, long64(strmid(pfafPadded, 0, nCode)), pfafMode, nMode
    print, 'huc12: pfafMode, nMode, nAssigned, ratio = ', pfafMode, nMode, nAssigned, double(nMode)/double(nAssigned)
    if(double(nMode)/double(nAssigned) lt 0.75d)then begin
     jCode = nCode-1
     break
    endif
   endfor

   ; get the Pfafstetter string
   pfafString = strmid(strtrim(pfafMode,2), 0, jCode)

  endelse

  ; identify trailing zeroes
  strLength  = strlen(pfafString)
  stringVec  = strarr(strLength)
  if(strLength gt 2)then begin
   reads, pfafString, stringVec, format='('+strtrim(strLength,2)+'(a1))'
   ixNoZero = stregex(strjoin(reverse(stringVec)),'[1-9]')
  endif else begin
   ixNoZero = 0
  endelse
  print, 'defineMode, pfafMode, pfafString, strLength, stringVec = ', defineMode, pfafMode, ' : ', pfafString, strLength, stringVec

  ; get the common code (remove trailing zeroes)
  commonCode = strmid(pfafString, 0, strLength-ixNoZero)

  ; get the desired length of the buffer
  ixCheck = where(origCheck[0:iDangle-1] eq commonCode, nCheck)
  if(nCheck ge 0)then                 maxBuffer = 3+2 ; 00x     (length = 3) plus 2 for extra space
  if(nCheck ge nCode)then             maxBuffer = 5+2 ; 00x0x   (length = 5) plus 2 for extra space 
  if(nCheck ge nCode*nCode+nCode)then maxBuffer = 7+2 ; 00x0x0x (length = 7) plus 2 for extra space

  ; get the maximum string length
  maxAllowed = maxLevel-maxBuffer-maxUpstream
  if(maxAllowed le 3)then begin
   print, 'maxLevel    = ', maxLevel
   print, 'maxBuffer   = ', maxBuffer
   print, 'maxUpstream = ', maxUpstream
   print, 'commonCode  = ', commonCode
   stop, 'really small allowable string'
  endif

  ; trim code if it is getting too big
  ;print, 'before trim: commonCode = ', commonCode
  if(strlen(commonCode) gt 10)then begin
   ; first try: trim at the last double zero
   ixDoubleZero = strpos(commonCode, '00', /reverse_search)
   if(ixDoubleZero gt 3)then commonCode = strmid(commonCode, 0, ixDoubleZero)
   ; second try, trim at the first double zero
   if(strlen(commonCode) gt 10)then begin
    ixDoubleZero = strpos(commonCode, '00')
    if(ixDoubleZero gt 3)then commonCode = strmid(commonCode, 0, ixDoubleZero)
   endif
   ; third try, limit to 10 digits
   if(strlen(commonCode) gt 10)then commonCode = strmid(commonCode, 0, 10)
  endif
  ;print, 'after trim: commonCode = ', commonCode

  ; *****
  ; * PROCESS DUPLICATE CODES...
  ; ****************************

  ; save the original code
  origCheck[iDangle] = commonCode

  ; ensure that we do not have duplicate codes
  if(iDangle gt 0)then begin

   ; conduct multiple trials
   for iTrial=0,nSuffix-1 do begin

    ; get the current count of common codes
    ixCheck = where(origCheck[0:iDangle-1] eq commonCode, nCheck)
    if(nCheck gt nSuffix)then stop, 'need more suffixes'

    ; update the common code
    if(iTrial eq 0)then begin
     commonCode = origCheck[iDangle] + pSuffix[(nCheck)+iTrial]
    endif else begin
     if(nCheck gt 0)then commonCode = origCheck[iDangle] + pSuffix[(nCheck)+iTrial]
    endelse
    ;print, 'origCheck[iDangle], commonCode, iDangle, iTrial, nCheck = ', origCheck[iDangle], ' : ', commonCode, iDangle, iTrial, nCheck

    ; finish if there are no duplicates
    if(nCheck eq 0)then break

    ; check
    if(iTrial eq nSuffix-1)then stop, 'ran out of codes'

   endfor  ; multiple trials

   ; check updated codes
   ixCheck = where(newCheck[0:iDangle-1] eq commonCode, nCheck)
   if(nCheck gt 0)then stop, 'unexpected duplicate code'

  ; if iDangle=0
  endif else begin
   commonCode = origCheck[iDangle] + pSuffix[0]
  endelse

  ; update codes
  newCheck[iDangle] = commonCode
  codeLength[iDangle] = strlen(commonCode)

  ; check
  print, nhdString+' '+commonCode+': ', iDangle, nDangle, totalArea_mizu[iMizu]
  if(strlen(commonCode) gt 18)then stop, 'code is too long'

  ; *****
  ; * ASSIGN COMMON HDMA CODE AND WRITE ATTRIBUTES...
  ; *************************************************

  ; replace the initial string with the common code
  tempCode = commonCode+strmid(pfafSubset,nLevels)
  pfafVec[segId_mizu_ix[ixSubset]]    = long64(tempCode)
  pfafCode_seg[comID_sh_ix[ixSubset]] = tempCode

  ; update the HRU Pfafstetter code
  pfafCode_hru[feature_ix] = long64(pfafCode_seg[comID_sh_ix[segment_ix]])

  ; write the new attributes
  defineAttributes, shpFile_new, 'pfafCode',  'notUsed', ixPfafCode       ; ixPfafCode  = column in the file
  writeAttributes,  shpFile_new, ixPfafCode, comID_sh_ix[ixSubset], pfafCode_seg[comID_sh_ix[ixSubset]]

  ;if(defineMode eq 'huc12')then stop
  ;if(strmid(commonCode,0,5) eq '90227')then stop
  ;if(strmid(commonCode,0,5) eq '90178')then stop
  ;if(strmid(commonCode,0,7) eq '9035702')then stop
  ;stop

 endfor  ; looping through dangling reaches

 print, 'maximum length of PfafCode = ', max(codeLength, iMax)
 print, 'longest dangle = ', iMax
 ;stop

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


