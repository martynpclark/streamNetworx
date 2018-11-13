pro navigateGreatLakes

; Used to navigate the coastline
;  - purpose: assign Pfaffstetter codes to dangling reaches

; define extent for lat/lon
latExtent = [24.00d,  53.0d]
lonExtent = [-125.d, -65.5d]

; Great lakes - full region
latRegion = [0.55, 0.90]
lonRegion = [0.55, 0.90]

; Great lakes - Lake Superior
;latRegion = [0.75, 0.90]
;lonRegion = [0.55, 0.70]

; Great lakes -- Lake Michigan / Lake Huron
;latRegion = [0.60, 0.80]
;lonRegion = [0.60, 0.80]

; Great lakes -- Erie
;latRegion = [0.55, 0.70]
;lonRegion = [0.65, 0.80]

; Great lakes -- Ontario
;latRegion = [0.60, 0.70]
;lonRegion = [0.75, 0.85]

; Great lakes -- small area
;latRegion = [0.65, 0.70]
;lonRegion = [0.80, 0.85]

; define plot extent
latMin = latExtent[0] + latRegion[0]*(latExtent[1] - latExtent[0])
latMax = latExtent[0] + latRegion[1]*(latExtent[1] - latExtent[0])
lonMin = lonExtent[0] + lonRegion[0]*(lonExtent[1] - lonExtent[0])
lonMax = lonExtent[0] + lonRegion[1]*(lonExtent[1] - lonExtent[0])

; setup plotting
setupPlotting, lonmin, latmin, lonmax, latmax

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

; close file
ncdf_close, nc_file

; *****
; * GET STREAM SEGMENTS...
; ************************

; get filename for the Great Lakes
shp_rootpath   = '/Volumes/d1/mclark/NHD_Plus/ancillary_data/nhdPlus_raw/'
shp_filepath    = shp_rootpath  + 'NHDPlusGL/NHDPlus04'
seg_filename    = shp_filepath + '/NHDSnapshot/Hydrography/NHDFlowline'
link_filename   = shp_filepath + '/NHDPlusAttributes/PlusFlow'

; get the desired attributes from the flow lines
get_attributes, seg_filename+'.dbf', 'COMID',     comId_sh
get_attributes, seg_filename+'.dbf', 'FTYPE',     typeCharacter
get_attributes, seg_filename+'.dbf', 'REACHCODE', reachCharacter

; get the linkages
get_attributes, link_filename+'.dbf', 'FROMCOMID', fromComid
get_attributes, link_filename+'.dbf', 'TOCOMID',   toComid

; get the number of shapes
nShapes = n_elements(comId_sh)

; get the shapefile
get_shapes, seg_filename+'.shp', seg_shapes

; *****
; * GET SUBSET OF DANGLING REACHES IN A SPECIFIC REGION...
; ********************************************************

; define unique string for save files
nameRegion = 'GL_04'
print, 'Processing ', nameRegion

; define path for .sav files
savePath = '/Volumes/d1/mclark/NHD_Plus/ancillary_data/idlSave/'

; match the netcdf seg id
matchName = savePath + 'matchMizu_nhdPlusRaw_' + nameRegion + '.sav'
if(file_test(matchName) eq 0)then begin
 print, 'Matching the file ' + matchName
 match, segId_mizu, comID_sh, segId_mizu_ix, comID_sh_ix
 save, segId_mizu_ix, comID_sh_ix, filename=matchName
endif else begin
 restore, matchName
endelse

; match the downstream links
matchName = savePath + 'matchTopo_nhdPlusRaw_' + nameRegion + '.sav'
if(file_test(matchName) eq 0)then begin
 print, 'Matching the file ' + matchName
 match, comId_sh, fromComid, comId_topo_ix, fromComid_ix
 save, comId_topo_ix, fromComid_ix, filename=matchName
endif else begin
 restore, matchName
endelse

; identify the downstream link
shape_toComID  = replicate(-9999L,    nShapes)
shape_toComID[comId_topo_ix] = toComid[fromComid_ix]

; *****
; * INITIAL PLOT...
; *****************

; loop through the subset
for iShape=0,nShapes-1 do begin

 ; get vectors
 x = (*(seg_shapes[iShape])).xVec
 y = (*(seg_shapes[iShape])).yVec

 ; restrict to the region
 if(min(x) ge lonMin and max(x) le lonmax and min(y) ge latMin and max(y) le latMax)then begin
  plots, x, y, color=powderBlue
  if(typeCharacter[iShape] eq 'Coastline')then begin
   plots, x, y, color=orange, thick=2
   ;print, mean(x), mean(y), comId_sh[iShape]
  endif
 endif

endfor

; *****
; * NAVIGATE THE COASTLINE...
; ***************************

; define "dangling" reaches that touch the coast
ixDangle = where(downSegId[segId_mizu_ix] le 0, nDangle)
iyDangle = comID_sh_ix[ixDangle]  ; indices of dangling reaches in the shapefile

; identify ids of downstream flowlines from the dangling reaches
idFlowline = shape_toComID[iyDangle] 

; define arrays for the dangling reaches
dangleIndx = replicate(-9999L,  nDangle)
dangleLake = replicate(-9999L,  nDangle)
dangleFrom = replicate(-9999L,  nDangle)
dangleToId = replicate(-9999L,  nDangle)
dangleHUC8 = replicate(-9999L,  nDangle)
danglePfaf = replicate(-9999LL, nDangle)
dangleArea = replicate(-9999d,  nDangle)

; get the maximum number of pfafstetter levels
maxLevel = 19  ; cannot have numbers with more than 19 digits

; define the pfafstetter code
mainStem = replicate(0B,  maxLevel,nDangle)

; define the Lake
nameLakes = ['Superior','Michigan','Erie','Ontario']
idLakes   = [2,4,6,8]  ; provide "room" for between lake IDs

; loop through lakes
for iLake=0,n_elements(nameLakes)-1 do begin

 ; *****
 ; * GET DANGLING REACHES FOR A GIVEN LAKE...
 ; ******************************************

 ; define the first coastal segment...
 case nameLakes[iLake] of
  'Superior' : idCoastStart = 904020522LL
  'Michigan' : idCoastStart = 904080119LL
  'Erie'     : idCoastStart =  30833992LL
  'Ontario'  : idCoastStart =  25374297LL
  else: stop, 'unknown lake'
 endcase
 
 ; initialize the coastal element
 idCoast = idCoastStart
 ixCoast = where(comId_sh eq idCoast, nMatch)
 nCoast  = 0
 
 ; get the number of coastal flowlines: navigate the coastline
 while (ixCoast[0] gt 0 and nMatch eq 1) do begin
  ixCoast = where(comId_sh eq shape_toComID[ixCoast[0]], nMatch)
  idCoast = comId_sh[ixCoast[0]]
  nCoast  = nCoast+1
 endwhile
 
 ; define array to navigate the coast (in order)
 comIdCoast = lonarr(nCoast)  ; id of a coastal flowline
 huc8_Coast = lonarr(nCoast)  ; HUC8 id of a coastal flowline

 ; initialize the coastal element
 idCoast = idCoastStart
 ixCoast = where(comId_sh eq idCoast, nMatch)
 nCoast  = 0
 
 ; navigate the coastline
 while (ixCoast[0] gt 0 and nMatch eq 1) do begin
 
  ; save the coastal ids
  comIdCoast[nCoast] = idCoast
  huc8_Coast[nCoast] = long(strmid(reachCharacter[ixCoast[0]], 0, 8))

  ; identify the dangling reaches
  ixFeed = where(idFlowline eq idCoast, nFeed)
  if(nFeed ge 1)then begin
   dangleIndx[ixFeed] = nCoast 
   dangleLake[ixFeed] = iLake+1 
   dangleToId[ixFeed] = idCoast 
   dangleFrom[ixFeed] = segId_mizu[segId_mizu_ix[ixDangle[ixFeed]]]
   dangleArea[ixFeed] = totalArea_mizu[segId_mizu_ix[ixDangle[ixFeed]]]
   dangleHUC8[ixFeed] = long(strmid(reachCharacter[comID_sh_ix[ixDangle[ixFeed]]], 0, 8))
  endif
 
  ; get the next coastal segment
  ixCoast = where(comId_sh eq shape_toComID[ixCoast[0]], nMatch)
  idCoast = comId_sh[ixCoast[0]]
  nCoast  = nCoast+1
 
 endwhile
 
 ; save the coastal links
 if(iLake eq 0)then begin
  region_huc8_Coast = huc8_Coast
  region_comIDCoast = comIdCoast
 endif else begin
  region_huc8_Coast = [region_huc8_Coast,huc8_Coast]
  region_comIDCoast = [region_comIDCoast,comIdCoast]
 endelse

 ; *****
 ; * GET THE PFAFSTETTER CODE FOR DANGLING REACHES...
 ; **************************************************

 ; check the pfafstetter level
 checkPfaf = replicate(0L, maxLevel)
 checkPfaf[0:1] = 1

 ; get the subset
 ixLake   = where(dangleLake eq iLake+1, nSubset)
 ixSorted = sort(dangleIndx[ixLake])
 ixSubset = ixLake[ixSorted]

 ; get the first two levels of the Pfafstetter code
 mainStem[0,ixSubset] = 6               ; 6 = St Lawrence River on the continental scale
 mainStem[1,ixSubset] = idLakes[iLake]  ; lake index ([2,4,6,8], moving west to east)
 iLevel = 2

 ; get the pfafstetter code
 areaDangle = dangleArea[ixSubset]
 ixDesire2  = lindgen(nSubset)
 pfafCode   = lonarr(nSubset)

 ; get the first tributaries
 ixDesire = ixDesire2
 coastalTrib, iLevel, areaDangle, ixDesire, pfafCode
 mainStem[iLevel,ixSubset[ixDesire]] = pfafCode
 iLevel = iLevel+1

 ; -- level 3 -----------------------------------------------------------------------------------

 ; loop through the pfaffstetter codes
 for pfaf3=1,9,2 do begin

  ; get subset
  pfafOld  = pfaf3 
  ixDesire = ixDesire2
  ixTemp = where(reform(mainStem[iLevel-1,ixSubset[ixDesire]]) eq pfafOld, nDesire)
  if(nDesire eq 0)then continue
  ixDesire = ixDesire[ixTemp]
  checkPfaf[iLevel] = 1

  ; get the upstream area of each coastal segment
  coastalTrib, iLevel, areaDangle, ixDesire, pfafCode
  mainStem[iLevel,ixSubset[ixDesire]] = pfafCode[ixDesire]
  ixDesire3 = ixDesire
  iLevel = iLevel+1

  ; -- level 4 ----------------------------------------------------------------------------------

  ; loop through the pfaffstetter codes
  for pfaf4=1,9,2 do begin
  
   ; get subset
   pfafOld  = pfaf4
   ixDesire = ixDesire3
   ixTemp = where(reform(mainStem[iLevel-1,ixSubset[ixDesire]]) eq pfafOld, nDesire)
   if(nDesire eq 0)then continue
   ixDesire = ixDesire[ixTemp]
   checkPfaf[iLevel] = 1
  
   ; get the upstream area of each coastal segment
   coastalTrib, iLevel, areaDangle, ixDesire, pfafCode
   mainStem[iLevel,ixSubset[ixDesire]] = pfafCode[ixDesire]
   ixDesire4 = ixDesire
   iLevel = iLevel+1

   ; -- level 5 ----------------------------------------------------------------------------------

   ; loop through the pfaffstetter codes
   for pfaf5=1,9,2 do begin

    ; get subset
    pfafOld  = pfaf5
    ixDesire = ixDesire4
    ixTemp = where(reform(mainStem[iLevel-1,ixSubset[ixDesire]]) eq pfafOld, nDesire)
    if(nDesire eq 0)then continue
    ixDesire = ixDesire[ixTemp]
    checkPfaf[iLevel] = 1

    ; get the upstream area of each coastal segment
    coastalTrib, iLevel, areaDangle, ixDesire, pfafCode
    mainStem[iLevel,ixSubset[ixDesire]] = pfafCode[ixDesire]
    ixDesire5 = ixDesire
    iLevel = iLevel+1

    ; -- level 6 ----------------------------------------------------------------------------------
   
    ; loop through the pfaffstetter codes
    for pfaf6=1,9,2 do begin
   
     ; get subset
     pfafOld  = pfaf6
     ixDesire = ixDesire5
     ixTemp = where(reform(mainStem[iLevel-1,ixSubset[ixDesire]]) eq pfafOld, nDesire)
     if(nDesire eq 0)then continue
     ixDesire = ixDesire[ixTemp]
     checkPfaf[iLevel] = 1
   
     ; get the upstream area of each coastal segment
     coastalTrib, iLevel, areaDangle, ixDesire, pfafCode
     mainStem[iLevel,ixSubset[ixDesire]] = pfafCode[ixDesire]
     ixDesire6 = ixDesire
     iLevel = iLevel+1

     ; -- level 7 ----------------------------------------------------------------------------------

     ; loop through the pfaffstetter codes
     for pfaf7=1,9,2 do begin

      ; get subset
      pfafOld  = pfaf7
      ixDesire = ixDesire6
      ixTemp = where(reform(mainStem[iLevel-1,ixSubset[ixDesire]]) eq pfafOld, nDesire)
      if(nDesire eq 0)then continue
      ixDesire = ixDesire[ixTemp]
      checkPfaf[iLevel] = 1

      ; get the upstream area of each coastal segment
      coastalTrib, iLevel, areaDangle, ixDesire, pfafCode
      mainStem[iLevel,ixSubset[ixDesire]] = pfafCode[ixDesire]
      ixDesire7 = ixDesire
      iLevel = iLevel+1

      ; -- level 8 ----------------------------------------------------------------------------------

      ; loop through the pfaffstetter codes
      for pfaf8=1,9,2 do begin

       ; get subset
       pfafOld  = pfaf8
       ixDesire = ixDesire7
       ixTemp = where(reform(mainStem[iLevel-1,ixSubset[ixDesire]]) eq pfafOld, nDesire)
       if(nDesire eq 0)then continue
       ixDesire = ixDesire[ixTemp]
       checkPfaf[iLevel] = 1

       ; get the upstream area of each coastal segment
       coastalTrib, iLevel, areaDangle, ixDesire, pfafCode
       mainStem[iLevel,ixSubset[ixDesire]] = pfafCode[ixDesire]
       ixDesire8 = ixDesire
       iLevel = iLevel+1

       ; -- level 9 ----------------------------------------------------------------------------------

       ; loop through the pfaffstetter codes
       for pfaf9=1,9,2 do begin

        ; get subset
        pfafOld  = pfaf9
        ixDesire = ixDesire8
        ixTemp = where(reform(mainStem[iLevel-1,ixSubset[ixDesire]]) eq pfafOld, nDesire)
        if(nDesire eq 0)then continue
        ixDesire = ixDesire[ixTemp]
        checkPfaf[iLevel] = 1

        ; get the upstream area of each coastal segment
        coastalTrib, iLevel, areaDangle, ixDesire, pfafCode
        mainStem[iLevel,ixSubset[ixDesire]] = pfafCode[ixDesire]
        ixDesire9 = ixDesire
        iLevel = iLevel+1

        ; -- level 10 ----------------------------------------------------------------------------------

        ; loop through the pfaffstetter codes
        for pfaf10=1,9,2 do begin

         ; get subset
         pfafOld  = pfaf10
         ixDesire = ixDesire9
         ixTemp = where(reform(mainStem[iLevel-1,ixSubset[ixDesire]]) eq pfafOld, nDesire)
         if(nDesire eq 0)then continue
         ixDesire = ixDesire[ixTemp]
         checkPfaf[iLevel] = 1

         ; get the upstream area of each coastal segment
         coastalTrib, iLevel, areaDangle, ixDesire, pfafCode
         mainStem[iLevel,ixSubset[ixDesire]] = pfafCode[ixDesire]
         ixDesire10 = ixDesire
         iLevel = iLevel+1

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
 
    ; update level
    iLevel = iLevel - 1

   endfor  ; looping through 5th level

   ; update level
   iLevel = iLevel - 1

  endfor  ; looping through 4th level

  ; update level
  iLevel = iLevel - 1

 endfor  ; looping through 3rd level

 ; get maximum levels
 deepPfaf = total(checkPfaf, /integer)

 ; plot
 for ixValid=0,nSubset-1 do begin
  ixIndex = ixLake[ixSorted[ixValid]]
  ixMatch = where(dangleFrom[ixIndex] eq comID_sh, nMatch)
  if(nMatch eq 1)then begin
   iShape = ixMatch[0]
   x = (*(seg_shapes[iShape])).xVec
   y = (*(seg_shapes[iShape])).yVec
   plots, x, y, color=(pfafCode[ixValid]+1)*25, thick=3
   print, 'x, y, area = ', iShape, ixValid, dangleIndx[ixIndex], mean(x), mean(y), $
    dangleArea[ixIndex], areaDangle[ixValid], mainStem[0:deepPfaf,ixIndex]
  endif
 endfor

endfor  ; loop through lakes

; get the valid reaches
ixValid = where(reform(mainStem[2,*]) gt 0, nValid)
print, 'nValid = ', nValid

; get the pfafstetter codes for the dangling reaches
for iSeg=0,nValid-1 do begin
 ixDesire = ixValid[iSeg]
 deepPfaf = total((mainStem[*,ixDesire] gt 0), /integer)
 iPower   = 10LL^reverse(long64(lindgen(deepPfaf)))
 iVector  = long64(mainStem[0:deepPfaf-1,ixDesire])
 danglePfaf[ixDesire] = total(iPower*iVector, /integer)  ; scalar operation
 print, iSeg, ixDesire, mainStem[0:deepPfaf-1,ixDesire], danglePfaf[ixDesire]
 if(danglePfaf[ixDesire] lt -99999)then stop
endfor

; *****
; * DEFINE AND WRITE NETCDF FILE... 
; *********************************

; get the size of the vectors
nCoast  = n_elements(conus_comIDCoast)
nDangle = n_elements(dangleToId)

; define filename
nc_filename = nc_filepath + 'navigateGreatLakes.nc'

; create file
ncid = ncdf_create(nc_filename, /clobber, /netcdf4_format)

 ; create dimension
 dimIdCoast  = ncdf_dimdef(ncid, 'coast',  nCoast)
 dimIdDangle = ncdf_dimdef(ncid, 'dangle', nDangle)

 ; create the variables
 varid = ncdf_vardef(ncid, 'huc8_Coast', [dimIdCoast],  /long)
 varid = ncdf_vardef(ncid, 'comIDCoast', [dimIdCoast],  /long)
 varid = ncdf_vardef(ncid, 'dangleToId', [dimIdDangle], /long)
 varid = ncdf_vardef(ncid, 'dangleFrom', [dimIdDangle], /long)
 varid = ncdf_vardef(ncid, 'dangleHUC8', [dimIdDangle], /long)
 varid = ncdf_vardef(ncid, 'dangleArea', [dimIdDangle], /double)
 varid = ncdf_vardef(ncid, 'danglePfaf', [dimIdDangle], /string)

; end file definitions
ncdf_control, ncid, /endef
ncdf_close, ncid

; open file for writing
ncid = ncdf_open(nc_filename, /write)

; get variable IDs
varid_huc8_Coast = ncdf_varid(ncid, 'huc8_Coast')
varid_comIDCoast = ncdf_varid(ncid, 'comIDCoast')
varid_dangleToId = ncdf_varid(ncid, 'dangleToId')
varid_dangleFrom = ncdf_varid(ncid, 'dangleFrom')
varid_dangleArea = ncdf_varid(ncid, 'dangleArea')
varid_dangleHUC8 = ncdf_varid(ncid, 'dangleHUC8')
varid_danglePfaf = ncdf_varid(ncid, 'danglePfaf')

; write variables
ncdf_varput, ncid, varid_huc8_Coast, region_huc8_Coast
ncdf_varput, ncid, varid_comIDCoast, region_comIDCoast
ncdf_varput, ncid, varid_dangleToId, dangleToId
ncdf_varput, ncid, varid_dangleFrom, dangleFrom
ncdf_varput, ncid, varid_dangleArea, dangleArea
ncdf_varput, ncid, varid_dangleHUC8, dangleHUC8
ncdf_varput, ncid, varid_danglePfaf, string(danglePfaf)

; close file
ncdf_close, ncid 

stop
end
