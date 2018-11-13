pro conusPfafstetter

; Used to compute pfafstetter indices over the conus

; define path for .sav files
savePath = '/Volumes/d1/mclark/NHD_Plus/ancillary_data/idlSave/'

; *****
; * SET UP PLOTTING...
; ********************

; get path to shapefile
shp_path = '/Volumes/d1/mclark/NHD_Plus/ancillary_data/nhdPlus_SHPs_final/'

; Define shapefiles
nhdFiles = [$
            ['MS','10U'], $
            ['CO','15' ], $
            ['CO','14' ], $
            ['GB','16' ], $
            ['GL','04' ], $
            ['CA','18' ], $
            ['MS','10L'], $
            ['MS','11' ], $
            ['MS','07' ], $
            ['MS','06' ], $
            ['MS','05' ], $
            ['MS','08' ], $
            ['RG','13' ], $
            ['TX','12' ], $
            ['SA','03N'], $
            ['SA','03S'], $
            ['SA','03W'], $
            ['MA','02' ], $
            ['NE','01' ], $
            ['SR','09' ], $
            ['PN','17' ]  ]

; define colors
red=1
orange=2
blue=3
lightBlue=4
powderBlue=5
deepskyBlue=6
lavender=7
seaGreen=8
tvlct, r, g, b, /get
makeColors, r, g, b
tvlct, r, g, b

; *****
; * READ THE NHD+ TOPOLOGY...
; ***************************

; define the NetCDF file
nc_filepath = '/Volumes/d1/mclark/NHD_Plus/ancillary_data/'
nc_filename = nc_filepath + 'NHDPlus2_updated-CONUS.nc'
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

; get the number of upstream reaches
for i=0,9 do begin
 ixMatch = where(upSeg_count eq i, nMatch)
 print, 'number of segments with ' +strtrim(i,2)+ ' upstream reaches = ' + strtrim(nMatch,2)
endfor

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
; * READ THE REACH CODE...
; ************************

; define the NetCDF file
nc_filepath = '/Volumes/d1/mclark/NHD_Plus/ancillary_data/'
nc_filename = nc_filepath + 'NHDPlus2_reachCode.nc'
print, 'Reading reach code'

; open file
nc_file = ncdf_open(nc_filename, /nowrite)

 ; get the comid
 ivar_id = ncdf_varid(nc_file,'comId')
 ncdf_varget, nc_file, ivar_id, comId_mizu

 ; get the reach code
 ivar_id = ncdf_varid(nc_file,'reachCode')
 ncdf_varget, nc_file, ivar_id, reachCode_mizu

; close file
ncdf_close, nc_file

; *****
; * READ THE DANGLING REACHES FOR THE COAST...
; ********************************************

; define the NetCDF file
nc_filepath = '/Volumes/d1/mclark/NHD_Plus/ancillary_data/'
nc_filename = nc_filepath + 'navigateCoast.nc'
print, 'Reading the dangling reaches'

; open file
nc_file = ncdf_open(nc_filename, /nowrite)

 ; get the Id of the dangling reaches
 ivar_id = ncdf_varid(nc_file,'dangleFrom')
 ncdf_varget, nc_file, ivar_id, dangleFrom

 ; get the area of the dangling reaches
 ivar_id = ncdf_varid(nc_file,'dangleArea')
 ncdf_varget, nc_file, ivar_id, dangleArea

 ; get the HUC8 of the dangling reaches
 ivar_id = ncdf_varid(nc_file,'dangleHUC8')
 ncdf_varget, nc_file, ivar_id, dangleHUC8

 ; get the Pfafstetter code of the dangling reaches
 ivar_id = ncdf_varid(nc_file,'danglePfaf')
 ncdf_varget, nc_file, ivar_id, danglePfaf

; close file
ncdf_close, nc_file

; match the dangling reaches with the coastal reaches
matchName = savePath + 'matchConusDangle.sav'
if(file_test(matchName) eq 0)then begin
 print, 'Matching the file ', matchName
 match, segId_mizu, dangleFrom, segIdCONUS_ix, dangleFrom_ix
 save, segIdCONUS_ix, dangleFrom_ix, filename=matchName
endif else begin
 restore, matchName
endelse

; *****
; * READ THE DANGLING REACHES FOR THE GREAT LAKES...
; **************************************************

; define the NetCDF file
nc_filepath = '/Volumes/d1/mclark/NHD_Plus/ancillary_data/'
nc_filename = nc_filepath + 'navigateGreatLakes.nc'
print, 'Reading the dangling reaches'

; open file
nc_file = ncdf_open(nc_filename, /nowrite)

 ; get the Id of the dangling reaches
 ivar_id = ncdf_varid(nc_file,'dangleFrom')
 ncdf_varget, nc_file, ivar_id, dangleFrom_greatLakes

 ; get the area of the dangling reaches
 ivar_id = ncdf_varid(nc_file,'dangleArea')
 ncdf_varget, nc_file, ivar_id, dangleArea_greatLakes

 ; get the HUC8 of the dangling reaches
 ivar_id = ncdf_varid(nc_file,'dangleHUC8')
 ncdf_varget, nc_file, ivar_id, dangleHUC8_greatLakes

 ; get the Pfafstetter code of the dangling reaches
 ivar_id = ncdf_varid(nc_file,'danglePfaf')
 ncdf_varget, nc_file, ivar_id, danglePfaf_greatLakes

; close file
ncdf_close, nc_file

; match the dangling reaches with the coastal reaches
matchName = savePath + 'matchGreatLakesDangle.sav'
if(file_test(matchName) eq 0)then begin
 print, 'Matching the file ', matchName
 match, segId_mizu, dangleFrom_greatLakes, segIdGreatLakes_ix, dangleFromGreatLakes_ix
 save, segIdGreatLakes_ix, dangleFromGreatLakes_ix, filename=matchName
endif else begin
 restore, matchName
endelse

; *****
; * DEFINE OUTPUT FILE...
; ***********************

; define the NetCDF file
nc_filepath = '/Volumes/d1/mclark/NHD_Plus/ancillary_data/'
nc_filename = nc_filepath + 'conusPfafstetter_dangle.nc'

; create file
if(file_test(nc_filename) eq 0)then begin
 print, 'Creating the NetCDF file for the Pfafstetter code'
 ncid = ncdf_create(nc_filename, /clobber, /netcdf4_format)

  ; create dimension
  dimId = ncdf_dimdef(ncid, 'seg', nSeg)

  ; create the shape variables
  varid = ncdf_vardef(ncid, 'segId',        [dimid], /long)
  varid = ncdf_vardef(ncid, 'pfafCode_seg', [dimid], /string)

 ; end file definitions
 ncdf_control, ncid, /endef
 ncdf_close, ncid
endif  ; if creating file

; write the comID
ncid = ncdf_open(nc_filename, /write)
segId_id = ncdf_varid(ncid, 'segId')
ncdf_varput, ncid, segId_id, segId_mizu
ncdf_close, ncid

; *****
; * GET PFAFSTETTER CODE FOR THE DANGLING REACHES THAT TOUCH THE COAST...
; ***********************************************************************

; define the maximum number of levels
maxLevel = 19  ; cannot have numbers with more than 19 digits

; define the pfafstetter code
mainStem = replicate(0L,  maxLevel,nSeg)
pfafVec  = replicate(0LL, nSeg)

; define pCode
pCode = replicate(0L, maxLevel)

; skip coastal reaches
;goto, done_coastal

; sort the dangling reaches w.r.t. upstream area
ixSort   = reverse( sort(totalArea_mizu[segIdCONUS_ix]) )

; get the number of dangling reaches
nDangle = n_elements(dangleFrom_ix)

; loop through the dangling reaches
for iDangle=0,nDangle-1 do begin

 ; get the indices 
 jDangle = segIdCONUS_ix[ixSort[iDangle]]
 kDangle = dangleFrom_ix[ixSort[iDangle]] 

 ; print progress
 print, 'coastal: iDangle, nDangle, area, pfaf = ', iDangle, nDangle, totalArea_mizu[jDangle], danglePfaf[kDangle]

 ; check a valid Pfaf code
 if(danglePfaf[kDangle] eq -9999)then continue

 ; get the pfafstetter code (remove trailing zeroes)
 iPower   = 0LL
 strPfaf  = strtrim(danglePfaf[kDangle],2)
 longPfaf = long64(strPfaf)
 while longPfaf mod 10LL^iPower eq 0 do iPower++
 pfafStart = longPfaf / 10LL^(iPower-1)
 nLevels   = strlen(strPfaf) - (iPower-1)

 ; initialize pCode
 for iPower=0LL,nLevels-1 do pCode[iPower] = long(strmid(strPfaf,iPower,1))
 ;print, 'pCode = ', pCode[0:nLevels-1]

 ; initialize levels
 iLevel = nLevels-1

 ; get the Pfafstetter codes
 danglePfafstetter, iLevel, jDangle, pCode, segId_mizu, upSeg_count, upsReach, totalArea_mizu, $  ; input
                    mainStem, pfafVec  ; output
 ;print, 'jDangle, pfafVec[jDangle] = ', jDangle, pfafVec[jDangle]
 ;stop, 'after Mississippi'

endfor  ; dangling reaches

; write the pfafstetter code
print, 'Writing the Pfafstetter code'
ncid    = ncdf_open(nc_filename, /write)
pfaf_id = ncdf_varid(ncid, 'pfafCode_seg')
ncdf_varput, ncid, pfaf_id, string(pfafVec)
ncdf_close, ncid

; label after coastal reaches
done_coastal:

; *****
; * GET PFAFSTETTER CODE FOR THE DANGLING REACHES THAT TOUCH THE GREAT LAKES...
; *****************************************************************************

; define the pfafstetter code
mainStem = replicate(0L,  maxLevel,nSeg)
pfafVec  = replicate(0LL, nSeg)

; define pCode
pCode = replicate(0L, maxLevel)

; skip greatLakes reaches
;goto, done_greatLakes

; sort the dangling reaches w.r.t. upstream area
ixSort   = reverse( sort(totalArea_mizu[segIdGreatLakes_ix]) )

; get the number of dangling reaches
nDangle = n_elements(dangleFromGreatLakes_ix)

; loop through the dangling reaches
for iDangle=0,nDangle-1 do begin

 ; get the indices 
 jDangle = segIdGreatLakes_ix[ixSort[iDangle]]
 kDangle = dangleFromGreatLakes_ix[ixSort[iDangle]] 

 ; print progress
 print, 'greatLakes: iDangle, nDangle, area, pfaf = ', iDangle, nDangle, totalArea_mizu[jDangle], danglePfaf_greatLakes[kDangle]

 ; check a valid Pfaf code
 if(danglePfaf_greatLakes[kDangle] eq -9999)then continue

 ; get the pfafstetter code (remove trailing zeroes)
 iPower   = 0LL
 strPfaf  = strtrim(danglePfaf_greatLakes[kDangle],2)
 longPfaf = long64(strPfaf)
 while longPfaf mod 10LL^iPower eq 0 do iPower++
 pfafStart = longPfaf / 10LL^(iPower-1)
 nLevels   = strlen(strPfaf) - (iPower-1)

 ; initialize pCode
 for iPower=0LL,nLevels-1 do pCode[iPower] = long(strmid(strPfaf,iPower,1))
 ;print, 'pCode = ', pCode[0:nLevels-1]

 ; initialize levels
 iLevel = nLevels-1

 ; get the Pfafstetter codes
 danglePfafstetter, iLevel, jDangle, pCode, segId_mizu, upSeg_count, upsReach, totalArea_mizu, $  ; input
                    mainStem, pfafVec  ; output
 ;print, 'jDangle, pfafVec[jDangle] = ', jDangle, pfafVec[jDangle]

endfor  ; dangling reaches

; write the pfafstetter code
print, 'Writing the Pfafstetter code'
ncid    = ncdf_open(nc_filename, /write)
pfaf_id = ncdf_varid(ncid, 'pfafCode_seg')
for iSeg=0,nSeg-1 do begin
 if(pfafVec[iSeg] gt 0)then ncdf_varput, ncid, pfaf_id, string(pfafVec[iSeg]), offset=[iSeg], count=1
endfor
ncdf_close, ncid

; label after coastal reaches
done_greatLakes:

; *****
; * GET PFAFSTETTER CODE FOR ALL OTHER DANGLING REACHES...
; ********************************************************

; read the pfafstetter code
ncid = ncdf_open(nc_filename, /nowrite)
pfaf_id = ncdf_varid(ncid, 'pfafCode_seg')
ncdf_varget, ncid, pfaf_id, pfafVec_string
ncdf_close, ncid

; convert string to long
pfafVec = long64(pfafVec_string)
pfafVec_string = strtrim(pfafVec_string,2)

; identify dangling reaches
ixDangle = where(downSegId le 0, nDangle)

; idetnify the dangling reaches already processed
izDangle = where(pfafVec[ixDangle] gt 0, nGotDangle)

; get the region code
idSubRegion_mizu = reachCode_mizu/10000L

; sort the dangling reaches w.r.t. upstream area
ixSort   = reverse( sort(totalArea_mizu[ixDangle]) )

idCheck = 16054418L
ixMatch = where(segId_mizu[ixDangle] eq idCheck, nMatch)
iyMatch = ixDangle[ixMatch[0]]
print, 'nMatch, segId_mizu[iyMatch], pfaf = ', nMatch, segId_mizu[iyMatch], pfafVec[iyMatch], reachCode_mizu[iyMatch], totalArea_mizu[iyMatch]

; loop through regions
for iRegion=0,n_elements(nhdFiles)/2-1 do begin

 ; get shapefile for an individual region
 shp_file = shp_path + 'Flowline_' + nhdFiles[0,iRegion] + '_' + nhdFiles[1,iRegion] + '.shp'
 get_attributes, shp_file, 'COMID',     comId_sh
 get_shapes, shp_file, seg_shapes
 print, shp_file
 
 ; get the match
 matchName = savePath + 'matchShape_merged_' + nhdFiles[0,iRegion] + '_' + nhdFiles[1,iRegion] + '.shp'
 if(file_test(matchName) eq 0)then begin
  print, 'Matching the file ', matchName
  match, segId_mizu, comID_sh, segId_mizu_ix, comID_sh_ix
  save, segId_mizu_ix, comID_sh_ix, filename=matchName
 endif else begin
  restore, matchName
 endelse

 ; loop through the dangling reaches
 for iDangle=0,nDangle-1 do begin

  ; get the indices
  jDangle = ixDangle[ixSort[iDangle]]
  if(pfafVec[jDangle] gt 0)then continue
  
  ; print progress
  print, 'iDangle, jDangle, segId, nDangle, area, pfaf = ', iDangle, jDangle, nDangle, segId_mizu[jDangle], totalArea_mizu[jDangle], pfafVec[jDangle]
  ;if(segId_mizu[jDangle] eq idCheck)then stop, 'desired reach'
  
  ; get the region code
  idSubregion = reachCode_mizu[jDangle]/10000L

  ; check if we are in the region
  case nhdFiles[1,iRegion] of

   ; Missouri
   '10U': isValid = ( (idSubregion ge 1001 and idSubregion le 1017) or segId_mizu[jDangle]/10000L eq 110000L)
   '10L': isValid =   (idSubregion ge 1018 and idSubregion le 1040)

   ; South Atlantic
   '03N': isValid = (idSubregion ge 301 and idSubregion le 306)
   '03S': isValid = (idSubregion ge 307 and idSubregion le 311)
   '03W': isValid = (idSubregion ge 312 and idSubregion le 318)

   ; include basins outside the USA (may not have a region code)
   '01':  isValid = (idSubregion/100LL eq  1 or segId_mizu[jDangle] eq 1010002391LL)
   '18':  isValid = (idSubregion/100LL eq 18 or segId_mizu[jDangle] eq 1180000368LL)
   '17':  isValid = (idSubregion/100LL eq 17 or segId_mizu[jDangle]/1000L eq 1171000L)
   '15':  isValid = (idSubregion/100LL eq 15 or segId_mizu[jDangle]/1000L eq 1150000L)
   '13':  isValid = (idSubregion/100LL eq 13 or segId_mizu[jDangle]/1000L eq 1131000L)

   ; everything else
   else:  isValid = (long(strtrim(nhdFiles[1,iRegion],2)) eq idSubregion/100LL)

  endcase

  ; skip
  if(isValid eq 0)then continue
  ;if(segId_mizu[jDangle] ne 25293410L)then continue

  print, 'segId       = ', segId_mizu[jDangle]
  print, 'reachCode   = ', reachCode_mizu[jDangle]
  print, 'idSubRegion = ', idSubRegion
  print, 'valid code  = ', isValid
 
  ; manually assign pfaf codes based on segId
  manualDangle, segId_mizu[jDangle], strPfaf
  print, 'strPfaf = ', strPfaf
 
  ; try to find the closest reach
  if(strPfaf eq 'unknown')then begin

   ; check the subregion
   ;if(reachCode_mizu[jDangle] eq 15030101L or reachCode_mizu[jDangle] eq 15030102L or reachCode_mizu[jDangle] eq 15030103L)then stop, 'check code'

   ; *****
   ; * MAKE A MAP...
   ; ***************

   ; define the desired reach
   idReachDesire = 19835180LL

   ; make the map
   makeTheMap = 0
   if(reachCode_mizu[jDangle] eq idReachDesire)then makeTheMap=1
   if(makeTheMap eq 1)then begin
  
    ; get indices in shape file and mizuroute file
    ixTest = where(comID_sh[comID_sh_ix] eq segId_mizu[jDangle], nMatch)
    if(nMatch ne 1)then stop, 'cannot find the dangling reach'
    iyTest = segId_mizu_ix[ixTest[0]]
    izTest = comID_sh_ix[ixTest[0]]
    print, ixTest[0], segId_mizu[jDangle], segId_mizu[iyTest], comID_sh[izTest]
   
    ; set up plotting
    xmean  = mean( (*(seg_shapes[izTest])).xVec )
    ymean  = mean( (*(seg_shapes[izTest])).yVec )
    scale  = 1.d * (sqrt(totalArea_mizu[iyTest])/100000.d + 0.01d) ; /1000 = m->km /100 = km->deg
    latmin = ymean - Scale
    latmax = ymean + Scale
    lonmin = xmean - Scale/cos(ymean * !pi/180.d)
    lonmax = xmean + Scale/cos(ymean * !pi/180.d)
    setupPlotting, lonmin, latmin, lonmax, latmax
    print, ymean, xmean
    print, lonmin, latmin, lonmax, latmax
   
    ; plot shapes
    for iSeg=0,n_elements(segId_mizu_ix)-1 do begin
   
     ; get indices
     ncSeg  = segId_mizu_ix[iSeg]
     iShape = comID_sh_ix[iSeg]
   
     ;  ; get the x and y vectors
     x = (*(seg_shapes[iShape])).xVec
     y = (*(seg_shapes[iShape])).yVec
   
     ; restrict to the region
     if(min(x) ge lonMin and max(x) le lonmax and min(y) ge latMin and max(y) le latMax)then begin
      plots, x, y, color=80, thick=1
      if(pfafVec[ncSeg] eq 0)then plots, x, y, color=210, thick=9
      if(comID_sh[iShape] eq segId_mizu[iyTest])then plots, x, y, color=250, thick=7
      if(reachCode_mizu[ncSeg]/10000L eq idSubRegion)then plots, x, y, color=120, thick=1
      if(reachCode_mizu[ncSeg]/100L   eq reachCode_mizu[jDangle]/100L)then plots, x, y, color=210, thick=1
      if(reachCode_mizu[ncSeg]        eq reachCode_mizu[jDangle]     )then begin
       if(totalArea_mizu[ncSeg] gt totalArea_mizu[jDangle])then plots, x, y, color=210, thick=3
       plots, x, y, color=250, thick=1
      endif
     endif
   
    endfor  ; looping through shapes
  
    ; get downstream Id in the mizuroute topology
    downId = downSegId[iyTest]
    print, 'downstream ID = ', downId

   endif  ; if making the map
   
   ; *****
   ; * GET THE PFAFSTETTER CODE...
   ; *****************************

   ; get the desired comID
   idComDesire = 20516599L

   ; identify shapes in the same cataloging unit
   ixMatch = where(reachCode_mizu[segId_mizu_ix] eq reachCode_mizu[jDangle], nMatch)
   if(nMatch eq 0)then stop, 'cannot identify basins in the same cataloging unit'

   ; identify dangling reaches in the same cataloging unit that do not have a Pfafstetter code
   iyMissing = where(pfafVec[segId_mizu_ix[ixMatch]] eq 0 and downSegId[segId_mizu_ix[ixMatch]] le 0, nMissing)
   if(nMissing eq 0)then stop, 'all basins in the cataloging unit have been assigned a Pfafstetter code'
  
   ; restrict attention to basins that have already been assigned a Pfafstetter code
   iyValid = where(pfafVec[segId_mizu_ix[ixMatch]] gt 0, nValid)
   if(nValid eq 0)then stop, 'none of the basins in the same cataloging unit have been assigned a Pfafstetter code'

   ; define the base Pfafstetter code
   basePfaf = lon64arr(nMissing)

   ; check enough data in the same region
   nDesire = 10
   if(nValid ge nDesire)then begin

    ; loop through missing codes
    for iMissing=0,nMissing-1 do begin

     ; get the coordinates of the target point
     iShape = comID_sh_ix[ixMatch[iyMissing[iMissing]]]
     xTarget = mean( (*(seg_shapes[iShape])).xVec )
     yTarget = mean( (*(seg_shapes[iShape])).yVec )
     print, 'yTarget, xTarget = ', yTarget, xTarget

     ; get the distance between the missing point and all valid points in the same region
     xDistance = dblarr(nValid)
     for iValid=0,nValid-1 do begin
      iShape  = comID_sh_ix[ixMatch[iyValid[iValid]]]
      xDesire = mean( (*(seg_shapes[iShape])).xVec )
      yDesire = mean( (*(seg_shapes[iShape])).yVec )
      xDistance[iValid] = map_2points(xTarget, yTarget, xDesire, yDesire, /meters)
     endfor
  
     ; get the maximum distance
     distMult = 25000.d  ; 25 km
     for iDist=1,100 do begin
  
      ; get the matches for a given distance
      distMax = double(iDist)*distMult
      izMatch=where(xDistance lt distMax, nmatch)
      print, iMissing, iDist, nMatch, distMax
      if(nMatch ge nDesire)then begin
 
       ; get desired indices
       ixDesire = segId_mizu_ix[ixMatch[iyValid[izMatch]]]

       ; get the length of the Pfafstetter code  
       cLen  = strlen( strtrim(pfafVec[ixDesire],2) )

       ; intialize the pfafstetter code
       cPfaf = strmid( strtrim(pfafVec[ixDesire[0]],2), 0, 1)
 
       ; loop through string elements
       for iPfaf=1,8 do begin

        ; get the values less than the length
        izValid = where(cLen gt iPfaf, mValid)
        if(mValid lt nDesire)then break
  
        ; get the integer vector
        intVec = long( strmid( strtrim(pfafVec[ixDesire[izValid]],2), iPfaf, 1) )
  
        ; get the mode
        distfreq = histogram(intVec, min=min(intVec))
        maxfreq  = max(distfreq)
        mode     = where(distfreq EQ maxfreq, count) + min(intVec)
  
        ; check more that the mode defines more than half of the values
        if(float(maxfreq)/float(nMatch) gt 0.25)then begin
         cPfaf = cPfaf + strtrim(mode[0],2)
  
        ; not a common number
        endif else begin
         mode = -1L
         break
        endelse
  
        ; check
        ;print, cPfaf, mode[0]
        ;print, intVec 
 
       endfor  ; looping through string elements
  
       ; got a match, so break
       break
  
      endif   ; if there was a match
  
     endfor  ; looping through distances

     ; save the base Pfafstetter code
     basePfaf[iMissing] = long64(cPfaf)

     ;print, 'basePfaf[iMissing] = ', basePfaf[iMissing]
     ;if(segId_mizu[segId_mizu_ix[ixMatch[iyMissing[iMissing]]]] eq 21271048L)then stop, 'stop: dangling reach'
  
    endfor  ; looping through missing values

   ; not many points in the same region
   endif else begin

    ; get the largest basin
    xMax    = max(totalArea_mizu[segId_mizu_ix[ixMatch[iyValid]]], iMax)
    jDesire = segId_mizu_ix[ixMatch[iyValid[iMax]]]

    ; get the base Pfafstetter code (remove trailing 1s)
    tempPfaf = long64(pfafVec[jDesire])
    while(tempPfaf mod 10 eq 1) do tempPfaf=tempPfaf/10  ; remove trailing 1s
    while(tempPfaf gt 10LL^8LL) do tempPfaf=tempPfaf/10  ; ensure that the Pfafstetter code is not too large
    print, 'area, pfaf, tempPfaf = ', segId_mizu[jDesire], totalArea_mizu[jDesire], pfafVec[jDesire], tempPfaf
 
    ; save
    basePfaf[*] = tempPfaf
 
   endelse

   ; ensure that the base Pfafstetter codes are unique
   print, 'basePfaf = ', basePfaf

   ; get unique Pfafstetter codes
   uniqPfaf = basePfaf[uniq(basePfaf, sort(basePfaf))]
   print, 'uniqPfaf = ', uniqPfaf

   ; ensure all Pfaf codes are unique
   for iUniq=0,n_elements(uniqPfaf)-1 do begin

    ; get the duplicate base Pfafstetter codes
    izDuplicate = where(basePfaf eq uniqPfaf[iUniq], nDuplicate)

    ; loop through basins in the cataloging unit from largest to smallest
    coords   = dblarr(2,nDuplicate)
    ixDesire = segId_mizu_ix[ixMatch[iyMissing[izDuplicate]]]
    ixSorted = reverse(sort(totalArea_mizu[ixDesire]))
  
    ; get coordinates for each basin
    for iAssign=0,nDuplicate-1 do begin
     iShape = comID_sh_ix[ixMatch[iyMissing[izDuplicate[iAssign]]]]
     coords[0,iAssign] = mean( (*(seg_shapes[iShape])).xVec )
     coords[1,iAssign] = mean( (*(seg_shapes[iShape])).yVec )
    endfor  ; loop through basins from largest to smallest
  
    ; assign Pfafstetter codes to the 9 basins with the largest area
    for iBasin=0,min([8,nDuplicate-1]) do begin
     jAssign = ixDesire[ixSorted[iBasin]]
     kAssign = izDuplicate[ixSorted[iBasin]]
     manualDangle, segId_mizu[jAssign], strPfaf
     if(strPfaf eq 'unknown')then pfafVec[jAssign] = basePfaf[kAssign]*100LL + (iBasin+1) else pfafVec[jAssign] = long64(strPfaf)
     print, 'big basin: reachCode_mizu[jDangle], reachCode_mizu[jAssign] = ', segId_mizu[jAssign], reachCode_mizu[jDangle], reachCode_mizu[jAssign], pfafVec[jAssign]
    endfor  ; looping through the first 9 basins

    ; assign Pfafstetter codes
    nAssign   = replicate(0L, 9)
    xDistance = dblarr(9)
    if(nDuplicate gt 9)then begin
     for iBasin=9,nDuplicate-1 do begin
      ; get the distance to each of the 9 biggest basins
      for jBasin=0,8 do xDistance[jBasin] = map_2points(coords[0,iBasin], coords[1,iBasin], coords[0,jBasin], coords[1,jBasin], /meters)
      ; identify which of the 4 biggest basins is cloest to the target basin
      aMin = min(xDistance, iMin)
      nAssign[iMin] = nAssign[iMin] + 1
      ; define a multiplier to enforce coding system 0[2,4,6,8]0[2,4,6,8]...
      iMult = 10LL^( (nAssign[iMin]-1)/9 + 2 )
      ; define indices
      jAssign = ixDesire[ixSorted[iBasin]]  ; target basin
      kAssign = ixDesire[ixSorted[iMin]]    ; closest big basin
      ; assign the Pfafstetter code
      manualDangle, segId_mizu[jAssign], strPfaf
      if(strPfaf eq 'unknown')then pfafVec[jAssign] = pfafVec[kAssign]*iMult + ( ((nAssign[iMin]-1) mod 9) + 1 ) else pfafVec[jAssign] = long64(strPfaf)
      ; check
      print, 'pfaf = ', iBasin, nMatch, segId_mizu[jAssign], coords[*,iBasin], pfafVec[jAssign], iMult, nAssign[iMin], format='(a,1x,2(i6,1x),i15,1x,2(f10.4,1x),2(i20,1x),i4)'
      if(pfafVec[jAssign] lt 0LL)then stop, 'long64 is not big enough to hold the Pfafstetter code'
     endfor
    endif    
  
    ; climb up the river network
    for iBasin=0,nDuplicate-1 do begin
  
     ; get the pfafstetter string
     jAssign = ixDesire[ixSorted[iBasin]]
     strPfaf = strtrim(pfafVec[jAssign],2)
  
     ; get the pfafstetter code
     pCode   = replicate(0L, maxLevel)
     nLevels = strlen(strPfaf)
     for iPower=0,nLevels-1 do pCode[iPower] = strmid(strPfaf,iPower,1)
  
     ; get the Pfafstetter codes
     iLevel = nLevels-1  ; initialize levels
     danglePfafstetter, iLevel, jAssign, pCode, segId_mizu, upSeg_count, upsReach, totalArea_mizu, $  ; input
                        mainStem, pfafVec  ; output
     print, 'jAssign, pfafVec[jAssign] = ', jAssign, pfafVec[jAssign]
  
     ;if(segId_mizu[jAssign] eq idCheck)then stop, 'checking reach 1'

    endfor ; basins within a region

   endfor ; unique basins

  endif else begin; if unknown strPfaf
  
   ; get the pfafstetter code
   pCode   = replicate(0L, maxLevel)
   nLevels = strlen(strPfaf)
   for iPower=0,nLevels-1 do pCode[iPower] = strmid(strPfaf,iPower,1)
  
   ; get the Pfafstetter codes
   iLevel = nLevels-1  ; initialize levels
   danglePfafstetter, iLevel, jDangle, pCode, segId_mizu, upSeg_count, upsReach, totalArea_mizu, $  ; input
                      mainStem, pfafVec  ; output
   print, 'jDangle, pfafVec[jDangle] = ', jDangle, pfafVec[jDangle]

   ;          ixMatch = where(strmid(strtrim(pfafVec,2),0,6) eq '692221', nMatch)
   ;          if(nMatch gt 0)then print, 'pfafVec = ', pfafVec[ixMatch] else print, 'pfafVec = missing' 

   ;          ; write the pfafstetter code
   ;          print, 'Writing the Pfafstetter code'
   ;          ncid    = ncdf_open(nc_filename, /write)
   ;          pfaf_id = ncdf_varid(ncid, 'pCode')
   ;          for iSeg=0,nSeg-1 do begin
   ;           if(strmid(strtrim(pfafVec[iSeg],2),0,4) eq '6922')then begin
   ;            ncdf_varput, ncid, pfaf_id, string(pfafVec[iSeg]), offset=[iSeg], count=1
   ;           endif
   ;          endfor
   ;          ncdf_close, ncid

   ;          stop, 'test Great Lakes'
 
  endelse

  ;if(segId_mizu[jDangle] eq idCheck)then stop, 'checking reach 2'
  
  ;    ; write the pfafstetter code
  ;    if(totalArea_mizu[jDangle] gt 1.d+10)then begin
  ;     print, 'Writing the Pfafstetter code'
  ;     ncid    = ncdf_open(nc_filename, /write)
  ;     pfaf_id = ncdf_varid(ncid, 'pCode')
  ;     for iSeg=0,nSeg-1 do begin
  ;      if(pfafVec[iSeg] gt 0)then ncdf_varput, ncid, pfaf_id, string(pfafVec[iSeg]), offset=[iSeg], count=1
  ;     endfor
  ;     ncdf_close, ncid
  ;    endif
  
  ; just do one unknown at a time
  ;if(totalArea_mizu[jDangle] lt 5.d+8)then stop
  ;if(totalArea_mizu[jDangle] lt 1.d+12)then stop

  ; check
  ;if(segId_mizu[jDangle] eq 25293410L)then stop, 'Grass/Raquette'

 endfor  ; looping through dangling reaches

 ;break
 ;stop, 'end of region'

endfor  ; looping through regions

; get the number of digits
ixDigits = strlen(strtrim(pfafVec,2))
print, 'Minimum Pfafstetter length = ', min(ixDigits)
print, 'Maximum Pfafstetter length = ', max(ixDigits)

; write the pfafstetter code
print, 'Writing the Pfafstetter code'
ncid    = ncdf_open(nc_filename, /write)
pfaf_id = ncdf_varid(ncid, 'pfafCode_seg')
ncdf_varput, ncid, pfaf_id, string(pfafVec)
ncdf_close, ncid


stop
end
