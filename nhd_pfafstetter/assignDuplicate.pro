pro assignDuplicate

; used to assign new codes to duplicate reaches

; define path for .sav files
savePath = '/Volumes/d1/mclark/NHD_Plus/ancillary_data/idlSave/'

; get path to shapefile
shp_path = '/Volumes/d1/mclark/NHD_Plus/ancillary_data/nhdPlus_SHPs_final/'

; Define shapefiles
nhdFiles = [$
            ['NE','01' ], $
            ['MA','02' ], $
            ['SA','03W'], $
            ['SA','03N'], $
            ['SA','03S'], $
            ['GL','04' ], $
            ['MS','05' ], $
            ['MS','06' ], $
            ['MS','07' ], $
            ['MS','08' ], $
            ['SR','09' ], $
            ['MS','10L'], $
            ['MS','10U'], $
            ['MS','11' ], $
            ['TX','12' ], $
            ['RG','13' ], $
            ['CO','14' ], $
            ['CO','15' ], $
            ['GB','16' ], $
            ['PN','17' ], $
            ['CA','18' ], $
            ['NE','01' ]  ]

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

; close file
ncdf_close, nc_file

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
; * READ PFAFSTETTER CODE...
; **************************

; define the NetCDF file
nc_filepath = '/Volumes/d1/mclark/NHD_Plus/ancillary_data/'
nc_filename = nc_filepath + 'conusPfafstetter_dangle.nc'

; read the pfafstetter code
print, 'Reading pfafstetter code'
ncid = ncdf_open(nc_filename, /nowrite)
pfaf_id = ncdf_varid(ncid, 'pfafCode_seg')
ncdf_varget, ncid, pfaf_id, pfafVec_string
ncdf_close, ncid

; convert string to long
pfafVec = long64(pfafVec_string)

; get rid of white space
pfafVec_string = strtrim(pfafVec_string,2)

; get the number of digits
ixDigits = strlen(pfafVec_string)
print, 'Minimum Pfafstetter length = ', min(ixDigits)
print, 'Maximum Pfafstetter length = ', max(ixDigits)

; get the number of stream segments
nSeg = n_elements(pfafVec)

; *****
; * CHECK FOR DUPLICATES...
; *************************

; define desired segment index
ixSegment = -9999  ; 4969 

; define flags for single (non-duplicate) reaches
ixSingle = replicate(0B, nSeg)

; initialize the counter for single reaches
nSingle = 0LL

; multiple trials -- needed to handle reaches with >5 unassigned segments
for iTrial=1,10 do begin

 ; define check array
 ixCheck  = replicate(0B, nSeg)

 ; initialize the old Pfafstetter code
 pCode_old = '9999'

 ; loop through stream segments
 for iSeg=0,nSeg-1 do begin

  ;print, iSeg, ixCheck[iSeg], ixSingle[iSeg], pfafVec[iSeg]

  ; define need to print progress
  printProgress = 0 ; (iSeg eq 2638)

  ; get the number of single reaches
  if(iSeg mod 1000L eq 0L)then nSingle = total(ixSingle, /integer)

  ; check that the segment is unprocessed
  if(ixCheck[iSeg] eq 1 or ixSingle[iSeg] eq 1 or pfafVec[iSeg] eq 0)then continue
  
  ; get the first four digits of the Pfafstetter code
  pCode = strmid(pfafVec_string[iSeg],0,6)
  
  ; get the matching strings
  if(pCode ne pCode_old)then ixMatch = where(strmatch(pfafVec_string, pCode+'*') eq 1, nMatch)
  if(nMatch eq 0)then stop, 'expect at least one match!'
  pCode_old = pCode
  
  ; print progress 
  if(iSeg mod 100L eq 0L)then $
   print, 'iSeg, pCode = ', iSeg, ' : ', pCode, nMatch, ixCheck[iSeg], nSingle
  
  ; loop through and see if there are any duplicates
  for jSeg=0,nMatch-1 do begin
 
   ; check if we have the duplicate already
   if(ixCheck[ixMatch[jSeg]] eq 1)then continue
  
   ; check for duplicates
   jxMatch = where(pfafVec[ixMatch[jSeg]] eq pfafVec[ixMatch[jSeg:nMatch-1]], nDuplicate)
   if(nDuplicate gt 1)then begin
  
    ; print progress
    if(printProgress eq 1)then begin
     print, 'jSeg = ', jSeg
     print, 'indices and pfaf codes = ', jxMatch, pfafVec[ixMatch[jSeg]], pfafVec[ixMatch[jxMatch+jSeg]]
     print, 'segment ids', segId_mizu[ixMatch[jxMatch+jSeg]]
     print, 'reach codes', reachCode_mizu[ixMatch[jxMatch+jSeg]]
     print, 'total area',  totalArea_mizu[ixMatch[jxMatch+jSeg]]
    endif
  
    ; get the number of bins
    case 1 of
     (nDuplicate lt 10):                        nBin = 1
     (nDuplicate ge 10) and (nDuplicate le 25): nBin = (nDuplicate-1 - 5)/4 +1
     else:                                      nBin = (nDuplicate-1 - 5)/4 +1
    endcase
  
    ; ========================================================================================================================
    ; ----- plotting code ----------------------------------------------------------------------------------------------------
    ; ========================================================================================================================
  
    ; define need for plotting
    plotting = (iSeg eq ixSegment)
    if(plotting eq 1)then begin
  
     ; get the subregion code
     idSubregion = reachCode_mizu[ixMatch[jSeg]]/10000L
    
     ; identify the region
     case 1 of
    
      ; Missouri
      ( (idSubregion ge 1001 and idSubregion le 1017) or segId_mizu[iSeg]/10000L eq 110000L): cRegion = '10U' 
        (idSubregion ge 1018 and idSubregion le 1040)                                       : cRegion = '10L' 
                                                                                                               
      ; South Atlantic
      (idSubregion ge 301 and idSubregion le 306)                                           : cRegion = '03N' 
      (idSubregion ge 307 and idSubregion le 311)                                           : cRegion = '03S' 
      (idSubregion ge 312 and idSubregion le 318)                                           : cRegion = '03W' 
                                                                                                               
      ; include basins outside the USA (may not have a region code)
      (idSubregion/100LL eq  1 or segId_mizu[iSeg]/10000L eq 101000L)                       : cRegion = '01'  
      (idSubregion/100LL eq 18 or segId_mizu[iSeg]/10000L eq 118000L)                       : cRegion = '18'  
      (idSubregion/100LL eq 17 or segId_mizu[iSeg]/10000L eq 117100L)                       : cRegion = '17'  
      (idSubregion/100LL eq 15 or segId_mizu[iSeg]/10000L eq 115000L)                       : cRegion = '15'  
      (idSubregion/100LL eq 13 or segId_mizu[iSeg]/10000L eq 113100L)                       : cRegion = '13'  
    
      ; everything else
      else:  cRegion = idSubregion/100LL
    
     endcase  ; identifying the region
   
     ; define the region
     jRegion = where(nhdFiles[1,*] eq cRegion)
     iRegion = jRegion[0]
     print, nhdFiles[0,iRegion] + '_' + nhdFiles[1,iRegion], ' : ', cRegion
   
     ; get shapefile for an individual region
     shp_file = shp_path + 'Flowline_' + nhdFiles[0,iRegion] + '_' + nhdFiles[1,iRegion] + '.shp'
     get_attributes, shp_file, 'COMID',     comId_sh
     get_shapes, shp_file, seg_shapes
     print, shp_file
     
     ; get the match
     matchName = savePath + 'matchShape_' + nhdFiles[0,iRegion] + '_' + nhdFiles[1,iRegion] + '.shp'
     if(file_test(matchName) eq 0)then begin
      print, 'Matching the file ', matchName
      match, segId_mizu, comID_sh, segId_mizu_ix, comID_sh_ix
      save, segId_mizu_ix, comID_sh_ix, filename=matchName
     endif else begin
      restore, matchName
     endelse
   
     ; get indices in shape file and mizuroute file
     ixTest = where(comID_sh[comID_sh_ix] eq segId_mizu[ixMatch[jSeg]], nTest)
     if(nTest ne 1)then stop, 'cannot find the duplicate reach'
     iyTest = segId_mizu_ix[ixTest[0]]
     izTest = comID_sh_ix[ixTest[0]]
     print, ixTest[0], segId_mizu[ixMatch[jSeg]], segId_mizu[iyTest], comID_sh[izTest]
   
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
   
     ; plot the shapes
     for iPlot=0,n_elements(segId_mizu_ix)-1 do begin
   
      ; get indices
      ncSeg  = segId_mizu_ix[iPlot]
      iShape = comID_sh_ix[iPlot]
   
      ; get the x and y vectors
      x = (*(seg_shapes[iShape])).xVec
      y = (*(seg_shapes[iShape])).yVec
   
      ; restrict to the region
      if(min(x) ge lonMin and max(x) le lonmax and min(y) ge latMin and max(y) le latMax)then begin
       plots, x, y, color=80, thick=1
       if(comID_sh[iShape] eq segId_mizu[iyTest])then plots, x, y, color=250, thick=7
      endif
   
     endfor  ; looping through shapes
   
     ; plot duplicates
     for iDuplicate=0,nDuplicate-1 do begin
   
      ; get the duplicate reach
      ixTest = where(comID_sh[comID_sh_ix] eq segId_mizu[ixMatch[jxMatch[iDuplicate]+jSeg]], nTest)
      if(nTest ne 1)then stop, 'cannot find the duplicate reach'
      iyTest = segId_mizu_ix[ixTest[0]]
      izTest = comID_sh_ix[ixTest[0]]
      print, ixTest[0], segId_mizu[ixMatch[jxMatch[iDuplicate]+jSeg]], segId_mizu[iyTest], comID_sh[izTest]
   
      ; get the x and y vectors
      x = (*(seg_shapes[izTest])).xVec
      y = (*(seg_shapes[izTest])).yVec
      plots, x, y, color=210, thick=3
   
     endfor  ; looping through duplicates

    endif  ; if plotting
  
    ; ========================================================================================================================
    ; ----- end of plotting code ---------------------------------------------------------------------------------------------
    ; ========================================================================================================================
  
    ; find the smallest area
    areaMin = min(totalArea_mizu[ixMatch[jxMatch+jSeg]], ixAreaMin)
    jReach  = ixMatch[jxMatch[ixAreaMin]+jSeg]
    ;print, 'areaMin = ', totalArea_mizu[jReach], areaMin
  
    ; define Pfafstetter code for a single level
    pNum  = min([nDuplicate,5])
    pTemp = reverse(indgen(pNum)*2+1)
    pCode = rebin(pTemp#replicate(1,nBin), nBin*pNum, /sample)
  
    ; assign reaches
    for iReach=0,nDuplicate-1 do begin
  
     ; update the pfafstetter code
     if(iReach lt nBin*5)then pfafVec[jReach] = pfafVec[jReach]*10LL + pCode[iReach] else pfafVec[jReach] = pfafVec[jReach]*10LL + 1
  
     ; print progress
     if(printProgress eq 1 or plotting eq 1)then begin
      print, 'segId, downSegId, pfafVec, area = ', segId_mizu[jReach], downSegId[jReach], pfafVec[jReach], totalArea_mizu[jReach]
     endif
  
     ; get the next reach
     ixDesire = where(downSegId[jReach] eq segId_mizu[ixMatch[jxMatch+jSeg]], nTest)
     if(nTest ne 1) then break
     jReach   = ixMatch[jxMatch[ixDesire[0]]+jSeg]

     ; check segment
     if(iSeg eq ixSegment)then stop, 'check segment'
  
    endfor   ; assigning reaches
  
    ; stop if plotting
    if(plotting eq 1)then stop, 'duplicate'
  
   endif  ; if there is a duplicate
  
   ; assign reaches
   ixCheck[ixMatch[jxMatch+jSeg]] = 1
  
   ; update single reaches
   if(nDuplicate eq 1)then begin
    nSingle = nSingle+1
    ixSingle[ixMatch[jxMatch+jSeg]] = 1
   endif
  
  endfor ; checking for duplicates

  ; check
  ;if(ixCheck[2638] eq 1)then stop, 'check what is going on'

 endfor  ; looping through stream segments

 ; get the number of non-duplicates
 numberSingle = total(ixSingle, /integer)
 print, 'number of single reaches = ', iTrial, numberSingle, nSeg
 if(numberSingle eq nSeg)then break

 ;print, 'ixSingle[0:9] = ', ixSingle[0:9]

endfor  ; looping through trials

; define new filename
nc_filename1 =  nc_filepath + 'conusPfafstetter_noDuplicate.nc'

; create new file
spawn, 'cp ' + nc_filename + ' ' + nc_filename1 

; write the pfafstetter code
print, 'Writing the Pfafstetter code'
ncid    = ncdf_open(nc_filename1, /write)
pfaf_id = ncdf_varid(ncid, 'pfafCode_seg')
ncdf_varput, ncid, pfaf_id, string(pfafVec)
ncdf_close, ncid

stop
end
