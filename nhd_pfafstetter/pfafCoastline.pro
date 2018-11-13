pro pfafCoastline

; used to assign Pfafstetter codes to the coastline

; Define base path
shp_rootpath = '/Volumes/d1/mclark/NHD_Plus/ancillary_data/'

; define path for .sav files
savePath = '/Volumes/d1/mclark/NHD_Plus/ancillary_data/idlSave/'

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

 ; get the total area
 ivar_id = ncdf_varid(nc_file,'totalArea')
 ncdf_varget, nc_file, ivar_id, totalArea_mizu

; close file
ncdf_close, nc_file

; *****
; * READ THE DANGLING REACHES...
; ******************************

; define the NetCDF file
nc_filepath = '/Volumes/d1/mclark/NHD_Plus/ancillary_data/'
nc_filename = nc_filepath + 'navigateCoast.nc'
print, 'Reading the dangling reaches'

; open file
nc_file = ncdf_open(nc_filename, /nowrite)

 ; get the comids for the coast
 ivar_id = ncdf_varid(nc_file,'comIDCoast')
 ncdf_varget, nc_file, ivar_id, comIDCoast

 ; get the huc8 for the coast
 ivar_id = ncdf_varid(nc_file,'huc8_Coast')
 ncdf_varget, nc_file, ivar_id, huc8_Coast

 ; get the Id of the dangling reaches
 ivar_id = ncdf_varid(nc_file,'dangleFrom')
 ncdf_varget, nc_file, ivar_id, dangleFrom

 ; get the downstream Id for the dangling reaches
 ivar_id = ncdf_varid(nc_file,'dangleToId')
 ncdf_varget, nc_file, ivar_id, dangleToId

 ; get the area of the dangling reaches
 ivar_id = ncdf_varid(nc_file,'dangleArea')
 ncdf_varget, nc_file, ivar_id, dangleArea

 ; get the HUC8 of the dangling reaches
 ivar_id = ncdf_varid(nc_file,'dangleHUC8')
 ncdf_varget, nc_file, ivar_id, dangleHUC8

; close file
ncdf_close, nc_file

; *****
; * MATCH VECTORS...
; ******************

; match the dangling reaches with the coastal reaches
matchName = savePath + 'matchAreaDangle.sav'
if(file_test(matchName) eq 0)then begin
 print, 'Matching the file ', matchName
 match, segId_mizu, dangleFrom, segId_mizu_ix, dangleFrom_ix
 save, segId_mizu_ix, dangleFrom_ix, filename=matchName
endif else begin
 restore, matchName
endelse

; match the dangling reaches with the coastal reaches
matchName = savePath + 'matchCoastalDangle.sav'
if(file_test(matchName) eq 0)then begin
 print, 'Matching the file ', matchName
 match, comIDCoast, dangleToId, comIDCoastDangle_ix, dangleToId_ix
 save, comIDCoastDangle_ix, dangleToId_ix, filename=matchName
endif else begin
 restore, matchName
endelse

; get the number of dangling reaches
nCoast_conus = n_elements(comIDCoast)

; super-impose the ID of the dangling reaches on the coastal flowlines
; NOTE: this could be a many-to-one assignment since multiple flowlines could reach a coastal segment
;         --> assign dangling reaches later
coastDangle = replicate(-9999L, nCoast_conus)
coastDangle[comIDCoastDangle_ix] = dangleFrom[dangleToId_ix]

; super-impose the area of the dangling reaches on the coastal flowlines
areaDangle = replicate(-9999d, nCoast_conus)
areaDangle[comIDCoastDangle_ix] = dangleArea[dangleToId_ix]

; define an array with the pfafstetter codes
coastPfaf = replicate(0, 20, nCoast_conus)

; *****
; * GET THE 1ST-LEVEL PFAFFSTETTER CODES...
; *****************************************

; define the coastal HUC2 regions
coastal_huc = [17,18,13,12,8,3,2,1]

; define the HUC2 regions
huc2_coast = floor(huc8_coast/1000000)

; define the pfafStetter code
pCodeCoast = replicate(-9999L, nCoast_conus)

; loop through the coastal HUCs
for iHUC=0,n_elements(coastal_huc)-1 do begin

 ; define the ID of a HUC
 idHUC = coastal_huc[iHUC]

 ; get the subset of dangling reaches in a given HUC2 region
 ixSubset = where(idHUC eq huc2_coast, nSubset)

 ; process the Mississippi (only basin in the conus with one of the four North American main stems)
 if(idHUC eq 8)then begin

  ; get the unique id of the coastal segment
  idTest  = 22811611L
  ixTest  = where(dangleFrom[dangleToId_ix[ixSubset]] eq idTest, nMatch)
  idCoast = comIDCoast[comIDCoastDangle_ix[ixSubset[ixTest[0]]]]
  if(idCoast ne dangleToId[dangleToId_ix[ixSubset[ixTest[0]]]])then stop, 'problem finding coastal ID'

  ; get the index of the coastal segment
  ixCoast = comIDCoastDangle_ix[ixSubset[ixTest[0]]]
  iyCoast = where(ixSubset le ixCoast, complement=izCoast)
  
  ; define the Pfaffstetter code
  pCodeCoast[ixSubset[iyCoast]] = 9
  pCodeCoast[ixSubset[izCoast]] = 7

  ; overwrite the tributary
  pCodeCoast[ixCoast] = 8

 ; process all other reaches
 endif else begin

  ; define the first-level Pfafstetter code
  case idHUC of
     17: pCodeCoast[ixSubset] = 1
     18: pCodeCoast[ixSubset] = 9
     13: pCodeCoast[ixSubset] = 9
     12: pCodeCoast[ixSubset] = 9
      3: pCodeCoast[ixSubset] = 7
      2: pCodeCoast[ixSubset] = 7
      1: pCodeCoast[ixSubset] = 7
   else: stop, 'cannot find region'
  endcase

 endelse  ; processing other reaches

endfor  ; looping through coastal HUCs

; save the Pfafstetter code
iLevel = 0
coastPfaf[iLevel,*] = pCodeCoast

; *****
; * GET THE 2nd-LEVEL PFAFFSTETTER CODES...
; *****************************************

; save the level-1 pfafstetter codes
oldPfaf = pCodeCoast

; initialize pCode (set to one since wirking counter clockwise)
pCodeCoast[*] = 1   ; NOTE: stop at the last tributary

; define inter-basins
tribBasins  = [2,4,6,8]
interBasins = [1,3,5,7,9]

; loop through the inter-basins in the first Pfafstetter level
for pfafOne=1,9,2 do begin

 ; get the count of a given code
 ixSubset = where(oldPfaf eq pfafOne, nSubset)
 if(nSubset eq 0)then continue

 ; identify major basins
 case pfafOne of   ;         2          4          6          8
     1: bigBasins = [23832907L,    -9999L,    -9999L,    -9999L]   ; Columbia, Fraser, Kuskokwim, Yukon
     7: bigBasins = [   -9999L,  4726685L,  2297884L, 18524217L]   ; St. John, Susquehanna, Apalachicola, Mobile
     9: bigBasins = [  626220L,    -9999L,    -9999L,  2788603L]   ; Rio Grande, La Pescadora, Colorado, Sacramento
  else: stop, 'do not expect inter-basin 3 or 5 (both northern Canada)'
 endcase

 ; define starting Pfafstetter code
 ixTrib = where(bigBasins gt 0, nTrib)

 ; loop through the tributaries
 for iTrib=0,nTrib-1 do begin

  ; try and find the index of the desired basin
  ixMatch = where(coastDangle[ixSubset] eq bigBasins[ixTrib[iTrib]], nMatch)
  if(nMatch ne 1)then stop, 'cannot find unique match to big basin'

  ; define the basin
  pCodeCoast[ixSubset[ixMatch]] = tribBasins[ixTrib[iTrib]]

  ; define the inter-basin
  iyMatch = where(ixSubset lt ixSubset[ixMatch[0]], nInterBasin)
  if(nInterBasin gt 0)then pCodeCoast[ixSubset[iyMatch]] = interBasins[ixTrib[iTrib]+1]  ; +1 because rotating anti-clockwise

  ; check
  if(pfafOne eq -9999)then begin
   print, pCodeCoast[ixSubset]
   print, 'bigBasins = ', bigBasins
   stop
  endif

 endfor  ;  looping through tributaries

endfor  ; looping through inter-basins

; south of the sacramento in california actually "7" because the colorado is "6" (colorado does not flow to ocean in the usa)
ixMatch = where(huc2_coast eq 18 and pCodeCoast eq 3, nMatch)
if(nMatch gt 0)then pCodeCoast[ixMatch] = 7

; north of the Susquehanna is actually "3" because the st john flows to the ocean in canada
ixMatch = where(huc2_coast le 2 and pCodeCoast eq 1, nMatch)
if(nMatch gt 0)then pCodeCoast[ixMatch] = 3

; the mississipi is actually 0 since just store the outlet
idTest  = 22811611L
ixTest  = where(dangleFrom[dangleToId_ix[ixSubset]] eq idTest, nMatch)
idCoast = comIDCoast[comIDCoastDangle_ix[ixSubset[ixTest[0]]]]
ixCoast = comIDCoastDangle_ix[ixSubset[ixTest[0]]]
pCodeCoast[ixCoast] = 0

; save the Pfafstetter code
iLevel = 1
coastPfaf[iLevel,*] = pCodeCoast

; *****
; * GET THE nth-LEVEL PFAFFSTETTER CODES...
; *****************************************

; initialize pfaffstetter checks
checkPfaf = replicate(0, 20)

; initialize level
iLevel=0
checkPfaf[iLevel] = 1

; loop through the first-level pfaffstetter codes
for pfaf1=1,9,2 do begin

 ; get a given code
 ixSubset = where(reform(coastPfaf[iLevel,*]) eq pfaf1, nSubset)
 if(nSubset eq 0)then continue

 ; -- level 2 -----------------------------------------------------------------------------------

 ; save Pfaf code
 iLevel = iLevel+1
 checkPfaf[iLevel] = 1
 ; (note: already have the pfaf code)

 ; get new level
 ixSubset1 = ixSubset
 pCodeCoast[ixSubset] = 0
 for pfaf2=1,9,2 do begin

  ; get the new subset
  ixTemp = where(reform(coastPfaf[iLevel,ixSubset1]) eq pfaf2, nSubset)
  if(nSubset eq 0)then continue
  ixSubset = ixSubset1[ixTemp]
  print, 'iLevel, nSubset = ', iLevel, nSubset

  ; get the upstream area of each coastal segment
  coastalTrib, reform(coastPfaf[iLevel,*]), areaDangle, ixSubset, pCodeCoast

  ; -- level 3 ----------------------------------------------------------------------------------

  ; save pfaf code
  iLevel = iLevel + 1
  checkPfaf[iLevel] = 1
  coastPfaf[iLevel,ixSubset] = pCodeCoast[ixSubset]

  ; get new level
  ixSubset2 = ixSubset
  pCodeCoast[ixSubset] = 0
  for pfaf3=1,9,2 do begin

   ; get the new subset
   ixTemp = where(reform(coastPfaf[iLevel,ixSubset2]) eq pfaf3, nSubset)
   if(nSubset eq 0)then continue
   ixSubset = ixSubset2[ixTemp]

   ; get the upstream area of each coastal segment
   coastalTrib, reform(coastPfaf[iLevel,*]), areaDangle, ixSubset, pCodeCoast

   ; -- level 4 ----------------------------------------------------------------------------------
  
   ; save pfaf code
   iLevel = iLevel + 1
   checkPfaf[iLevel] = 1
   coastPfaf[iLevel,ixSubset] = pCodeCoast[ixSubset]
  
   ; get new level
   ixSubset3 = ixSubset
   pCodeCoast[ixSubset] = 0
   for pfaf4=1,9,2 do begin
 
    ; get the new subset
    ixTemp = where(reform(coastPfaf[iLevel,ixSubset3]) eq pfaf4, nSubset)
    if(nSubset eq 0)then continue
    ixSubset = ixSubset3[ixTemp]
  
    ; get the upstream area of each coastal segment
    coastalTrib, reform(coastPfaf[iLevel,*]), areaDangle, ixSubset, pCodeCoast

    ; -- level 4 ----------------------------------------------------------------------------------

    ; save pfaf code
    iLevel = iLevel + 1
    checkPfaf[iLevel] = 1
    coastPfaf[iLevel,ixSubset] = pCodeCoast[ixSubset]

    ; get new level
    ixSubset4 = ixSubset
    pCodeCoast[ixSubset] = 0
    for pfaf5=1,9,2 do begin

     ; get the new subset
     ixTemp = where(reform(coastPfaf[iLevel,ixSubset4]) eq pfaf5, nSubset)
     if(nSubset eq 0)then continue
     ixSubset = ixSubset4[ixTemp]

     ; get the upstream area of each coastal segment
     coastalTrib, reform(coastPfaf[iLevel,*]), areaDangle, ixSubset, pCodeCoast

     ; -- level 5 ----------------------------------------------------------------------------------
  
     ; save pfaf code
     iLevel = iLevel + 1
     checkPfaf[iLevel] = 1
     coastPfaf[iLevel,ixSubset] = pCodeCoast[ixSubset]
  
     ; get new level
     ixSubset5 = ixSubset
     pCodeCoast[ixSubset] = 0
     for pfaf6=1,9,2 do begin
  
      ; get the new subset
      ixTemp = where(reform(coastPfaf[iLevel,ixSubset5]) eq pfaf6, nSubset)
      if(nSubset eq 0)then continue
      ixSubset = ixSubset5[ixTemp]
  
      ; get the upstream area of each coastal segment
      coastalTrib, reform(coastPfaf[iLevel,*]), areaDangle, ixSubset, pCodeCoast

      ; -- level 6 ----------------------------------------------------------------------------------

      ; save pfaf code
      iLevel = iLevel + 1
      checkPfaf[iLevel] = 1
      coastPfaf[iLevel,ixSubset] = pCodeCoast[ixSubset]

      ; get new level
      ixSubset6 = ixSubset
      pCodeCoast[ixSubset] = 0
      for pfaf7=1,9,2 do begin

       ; get the new subset
       ixTemp = where(reform(coastPfaf[iLevel,ixSubset6]) eq pfaf7, nSubset)
       if(nSubset eq 0)then continue
       ixSubset = ixSubset6[ixTemp]

       ; get the upstream area of each coastal segment
       coastalTrib, reform(coastPfaf[iLevel,*]), areaDangle, ixSubset, pCodeCoast

       ; -- level 7 ----------------------------------------------------------------------------------

       ; save pfaf code
       iLevel = iLevel + 1
       checkPfaf[iLevel] = 1
       coastPfaf[iLevel,ixSubset] = pCodeCoast[ixSubset]

       ; get new level
       ixSubset7 = ixSubset
       pCodeCoast[ixSubset] = 0
       for pfaf8=1,9,2 do begin

        ; get the new subset
        ixTemp = where(reform(coastPfaf[iLevel,ixSubset7]) eq pfaf8, nSubset)
        if(nSubset eq 0)then continue
        ixSubset = ixSubset7[ixTemp]

        ; get the upstream area of each coastal segment
        coastalTrib, reform(coastPfaf[iLevel,*]), areaDangle, ixSubset, pCodeCoast

        ; -- level 8 ----------------------------------------------------------------------------------

        ; save pfaf code
        iLevel = iLevel + 1
        checkPfaf[iLevel] = 1
        coastPfaf[iLevel,ixSubset] = pCodeCoast[ixSubset]

        ; get new level
        ixSubset8 = ixSubset
        pCodeCoast[ixSubset] = 0
        for pfaf9=1,9,2 do begin

         ; get the new subset
         ixTemp = where(reform(coastPfaf[iLevel,ixSubset8]) eq pfaf9, nSubset)
         if(nSubset eq 0)then continue
         ixSubset = ixSubset8[ixTemp]

         ; get the upstream area of each coastal segment
         coastalTrib, reform(coastPfaf[iLevel,*]), areaDangle, ixSubset, pCodeCoast

         ; -- level 9 ----------------------------------------------------------------------------------

         ; save pfaf code
         iLevel = iLevel + 1
         checkPfaf[iLevel] = 1
         coastPfaf[iLevel,ixSubset] = pCodeCoast[ixSubset]

         ; get new level
         ixSubset9 = ixSubset
         pCodeCoast[ixSubset] = 0
         for pfaf10=1,9,2 do begin

          ; get the new subset
          ixTemp = where(reform(coastPfaf[iLevel,ixSubset9]) eq pfaf10, nSubset)
          if(nSubset eq 0)then continue
          ixSubset = ixSubset9[ixTemp]

          ; get the upstream area of each coastal segment
          coastalTrib, reform(coastPfaf[iLevel,*]), areaDangle, ixSubset, pCodeCoast

          ; -- level 10 ----------------------------------------------------------------------------------
  
          ; save pfaf code
          iLevel = iLevel + 1
          checkPfaf[iLevel] = 1
          coastPfaf[iLevel,ixSubset] = pCodeCoast[ixSubset]

          ; get new level
          ixSubset10 = ixSubset
          pCodeCoast[ixSubset] = 0
          for pfaf11=1,9,2 do begin
  
           ; get the new subset
           ixTemp = where(reform(coastPfaf[iLevel,ixSubset10]) eq pfaf11, nSubset)
           if(nSubset eq 0)then continue
           ixSubset = ixSubset10[ixTemp]
  
           ; get the upstream area of each coastal segment
           coastalTrib, reform(coastPfaf[iLevel,*]), areaDangle, ixSubset, pCodeCoast

           ; -- level 11 ----------------------------------------------------------------------------------

           ; save pfaf code
           iLevel = iLevel + 1
           checkPfaf[iLevel] = 1
           coastPfaf[iLevel,ixSubset] = pCodeCoast[ixSubset]

           ; get new level
           ixSubset11 = ixSubset
           pCodeCoast[ixSubset] = 0
           for pfaf12=1,9,2 do begin

            ; get the new subset
            ixTemp = where(reform(coastPfaf[iLevel,ixSubset11]) eq pfaf12, nSubset)
            if(nSubset eq 0)then continue
            ixSubset = ixSubset11[ixTemp]

            ; get the upstream area of each coastal segment
            coastalTrib, reform(coastPfaf[iLevel,*]), areaDangle, ixSubset, pCodeCoast

            ; save pfaf code
            iLevel = iLevel + 1
            checkPfaf[iLevel] = 1
            coastPfaf[iLevel,ixSubset] = pCodeCoast[ixSubset]

            ; update level
            iLevel = iLevel - 1

           endfor  ; looping through 12th level
  
           ; update level
           iLevel = iLevel - 1

          endfor  ; looping through 11th level

          ; update level
          iLevel = iLevel - 1

         endfor  ; looping through 10th level

         ; update level
         iLevel = iLevel - 1

        endfor  ; looping through 9th level
 
        ; update level
        iLevel = iLevel - 1

       endfor  ; looping through 8th level

       ; update level
       iLevel = iLevel - 1

      endfor  ; looping through 7th level

      ; update level
      iLevel = iLevel - 1 

     endfor  ; looping through 6th level

     ; ---------------------------------------------------------------------------------------------

     ; update level
     iLevel = iLevel - 1

    endfor  ; looping through 5th level

    ; update level
    iLevel = iLevel - 1 

   endfor  ; looping through 4th level

   ; update level
   iLevel = iLevel - 1

  endfor  ; looping through 3rd level

  ; update level
  iLevel = iLevel - 1

 endfor  ; looping through 2nd level

 ; update level
 iLevel = iLevel - 1

endfor  ; looping through 1st level

; get pfafstetter code
nLevels  = total(checkPfaf, /integer)
pfafCode = reform(10LL^reverse(long64(lindgen(nLevels))) # long64(coastPfaf[0:nLevels-1,*]))

; check that the code is OK
ixCheck = where(pfafCode mod 2 ne 0 and coastDangle ne -9999L, nMissing)

print, 'nMissing = ', nMissing
if(nMissing gt 0)then print, transpose([[pfafCode[ixCheck]], [coastDangle[ixCheck]]])

; *****
; * WRITE THE NETCDF FILE...
; **************************

; put the data back in the arrays
nDangle = n_elements(dangleFrom)
danglePfaf = replicate(-9999LL, nDangle)
danglePfaf[dangleToId_ix] = pfafCode[comIDCoastDangle_ix]

; define the NetCDF file
nc_filepath = '/Volumes/d1/mclark/NHD_Plus/ancillary_data/'
nc_filename = nc_filepath + 'navigateCoast.nc'
print, 'Writing the Pfafstetter code'

; redefine file
ncid = ncdf_open(nc_filename, /write)
ncdf_control, ncid, /redef

 ; identify dimension
 dimIdDangle = ncdf_dimid(ncid, 'dangle')

 ; create the variables
 varid_danglePfaf = ncdf_vardef(ncid, 'danglePfaf', [dimIdDangle], /string)

; end file definitions
ncdf_control, ncid, /endef

; write variable
ncdf_varput, ncid, varid_danglePfaf, string(danglePfaf)

; close file
ncdf_close, ncid

stop
end
