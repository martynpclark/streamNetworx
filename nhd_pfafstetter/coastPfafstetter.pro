pro coastPfafstetter

; Used to identify Pfafstetter codes for the coastline
;  - including the Great Lakes

; Define the path to the geospatial data
base_filepath = '/Users/mac414/geospatial_data/NHD_Plus/ancillary_data/'

; define path for IDL .sav files
savePath = base_filepath + 'idlSave/'

; Define shapefiles for coastal regions
nhdFiles = [$
            ['NE','01' ], $
            ['MA','02' ], $
            ['SA','03N'], $ 
            ['SA','03S'], $ 
            ['SA','03W'], $ 
            ['MS','08' ], $
            ['TX','12' ], $
            ['RG','13' ], $
            ['CA','18' ], $
            ['PN','17' ], $
            ['GL','04' ]  ] ; (include Great Lakes)

; define entity types
typePoly = 5 ; entityType=5 is a polygon
typeLine = 3 ; entityType=3 is a polyLine

; initialize first pass
firstPass=1

; define missing values
doubleMissing = 1.d+15  ; bigger than the Mississippi

; define new shapefile
shapeFile_init = base_filepath + 'nhdPlus_SHPs_coast/conusCoast_init.shp'

; initialize unassigned reaches
idUnassigned = !NULL

; get additional codes (2-level)
pCode = indgen(5)*2+1
pTemp = pCode#replicate(1,5)
pLev2 = reform(transpose(pTemp*10) + pTemp, 25)

; get additional codes (3-level)
p100  = rebin(replicate(1,5)#pCode, 5, 25, /sample)
p010  = rebin(reform(rebin(pcode, 5, 5, /sample), 1, 25), 5, 25, /sample)
p001  = rebin(pCode, 5, 25, /sample)
pLev3 = reform(p100*100 + p010*10 + p001, 125)

; get additional codes (4-level)
pTemp = rebin(reform(transpose(p010), 1, 125), 5, 125, /sample)
p1000 = rebin(p100*1000 + p010*100, 5, 125, /sample) + pTemp*10
pLev4 = reform(p1000 + rebin(pCode, 5, 125, /sample), 625)

; *****
; * READ THE NHD+ TOPOLOGY...
; ***************************

; define the NetCDF file
nc_filename = base_filepath + 'NHDPlus2_updated-CONUS.nc'
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

; =============================================================================================
; =============================================================================================
; =============================================================================================
; =============================================================================================

; define IDL save file
coastalSave_conus =  savePath + 'coastalSave_conus.sav'
;spawn, 'rm ' + coastalSave_conus

; check if the save file exists
if(file_test(coastalSave_conus) eq 0)then begin

 ; initialize new conus shapefile
 commandText = 'rm -f ' + file_dirname(shapeFile_init) + '/' + file_basename(shapeFile_init, '.shp') + '*'
 spawn, commandText  ; remove the shapefile
 ixNewShape = 0      ; initialize counter for the new shapefile

 ; loop through shapefiles
 for iRegion=0,n_elements(nhdFiles)/2-1 do begin

  ; *****
  ; * GET STREAM SEGMENTS...
  ; ************************
  
  ; define unique string for save files
  nameRegion = nhdFiles[0,iRegion] + '_' + nhdFiles[1,iRegion]
  print, 'Processing ', nameRegion
  ;if(nameRegion ne 'GL_04')then continue

  ; get filename
  shp_rootpath   = base_filepath + 'nhdPlus_raw/'
  shp_filepath   = shp_rootpath  + 'NHDPlus'+nhdFiles[0,iRegion] + '/NHDPlus'+nhdFiles[1,iRegion]
  seg_filename   = shp_filepath + '/NHDSnapshot/Hydrography/NHDFlowline'
  link_filename  = shp_filepath + '/NHDPlusAttributes/PlusFlow'
  
  ; get the desired attributes from the flow lines
  get_attributes, seg_filename+'.dbf', 'COMID',     comId_sh
  get_attributes, seg_filename+'.dbf', 'REACHCODE', reachCharacter
  get_attributes, seg_filename+'.dbf', 'FTYPE',     typeFlowline
  
  ; get the linkages
  get_attributes, link_filename+'.dbf', 'FROMCOMID', fromComid
  get_attributes, link_filename+'.dbf', 'TOCOMID',   toComid
  
  ; read shapes
  get_shapes, seg_filename+'.shp', flowline_shapes
  
  ; get the number of shapes
  nShapes = n_elements(comId_sh)
  
  ; *****
  ; * GET SUBSET OF DANGLING REACHES IN A SPECIFIC REGION...
  ; ********************************************************
  
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
  
  ; identify the upstream area
  shape_upsArea  =  replicate(doubleMissing,  nShapes)
  shape_upsArea[comID_sh_ix] = totalArea_mizu[segId_mizu_ix]
  
  ; restrict attention to the coastline flowlines
  ixCoastSubset = where(typeFlowline[comId_topo_ix] eq 'Coastline', nCoastSubset)
  if(nCoastSubset eq 0)then stop, 'expect coastline flowlines'
  
  ; identify the downstream link
  shape_toComID  = replicate(-9999L,    nShapes)
  shape_toComID[comId_topo_ix[ixCoastSubset]] = toComid[fromComid_ix[ixCoastSubset]]

  ; *****
  ; * IDENTIFY DANGLING REACHES AND INITIALIZE COASTAL NAVIGATION...
  ; ****************************************************************
  
  ; define "dangling" reaches that touch the coast
  ixDangle = where(downSegId[segId_mizu_ix] le 0, nDangle)
  iyDangle = comID_sh_ix[ixDangle]  ; indices of dangling reaches in the shapefile
  
  ; identify ids of downstream flowlines from the dangling reaches
  idFlowline = shape_toComID[iyDangle] 

  ; define starting coastal segments
  idCoastStart = call_function('idCoastStart', nameRegion)

  ; get any unassigned reaches that link to the previous region
  idUnassigned = call_function('idUnassigned', nameRegion) 
  if(n_elements(idUnassigned) gt 1)then stop, 'expect no more than one unassigned elements'

  ; =====================================================
  ; =====================================================
  
  ; loop through sub-regions
  for iSubRegion=0,n_elements(idCoastStart)-1 do begin
  
   ; *****
   ; * INITIALIZE DATA STRUCTURES DEFINING COASTAL FLOWLINES...
   ; **********************************************************
   
   ; initialize the coastal element
   idCoast = idCoastStart[iSubregion]
   ixCoast = where(shape_toComID eq idCoast, nMatch)
   nCoast  = 1 ; save the last flowline
  
   ; get the number of coastal flowlines: navigate the coastline
   while (ixCoast[0] gt 0 and nMatch eq 1) do begin
    ixCoast = where(shape_toComID eq idCoast, nMatch)
    if(nMatch eq 1)then begin
     idCoast = comId_sh[ixCoast[0]]
     nCoast  = nCoast+1
    endif
   endwhile

   ; define array to navigate the coast (in order)
   comIdCoast = lonarr(nCoast)  ; id of a coastal flowline
   huc8_Coast = lonarr(nCoast)  ; HUC8 id of a coastal flowline
   nUps_Coast = lonarr(nCoast)  ; number of flowlines "upstream" of the coastal flowline
   ups_struct = ptrarr(nCoast, /allocate_heap)  ; vector of upstream ids/indices for each coastline flowline
   
   ; initialize the coastal element
   idCoast = idCoastStart[iSubregion]
   ixCoast = where(comId_sh eq idCoast, nMatch)

   ; get ids, mask, and area
   if(n_elements(idUnassigned) eq 0)then begin
    ixVec   = [   ixCoast[0]     ] 
    idVec   = [   idCoast        ]
    maskVec = [   0              ] ; 0 = coastline
    areaVec = [   doubleMissing  ] ; doubleMissing is a very big value

   ; get vectors of ids, mask, and area -- to include unassigned area
   endif else begin

    ; identify the index of the unassigned reach
    ixMatch = where(idUnassigned[0] eq comid_sh, nMatch)
    if(nMatch ne 1)then stop, 'expect unique match for the unassigned reach'

    ; get concatenated vectors
    ixVec    = [ixCoast,       ixMatch]
    idVec    = [idCoast,       idUnassigned]
    maskVec  = [0,             1]
    areaVec  = [doubleMissing, shape_upsArea[ixMatch] ]

   endelse 

   ; write the initial elements to the shape file 
   for iShape=0,n_elements(idVec)-1 do begin
    writeShapefile, typeLine, ixVec[iShape], ixNewShape, idVec[iShape], shapeFile_init, flowline_shapes
    defineAttributes, shapeFile_init, 'coastMask', 'integer', ixCoastMask    ; ixCoastMask = column in the file
    defineAttributes, shapeFile_init, 'upsArea',   'float',   ixUpsArea      ; ixUpsArea = column in the file 
    writeAttributes,  shapeFile_init, ixCoastMask, ixNewShape, maskVec[iShape]
    writeAttributes,  shapeFile_init, ixUpsArea,   ixNewShape, areaVec[iShape] 
    ixNewShape = ixNewShape +1
   endfor  ; looping through shapes 

   ; *****
   ; * NAVIGATE THE COASTLINE, AND POPULATE DATA STRUCTURES DEFINING COASTAL FLOWLINES...
   ; ************************************************************************************
   
   ; navigate the coastline
   for jxCoast=0,nCoast-1 do begin
   
    ; save the coastal ids
    comIdCoast[jxCoast] = idCoast
    huc8_Coast[jxCoast] = long(strmid(reachCharacter[ixCoast[0]], 0, 8))

    ; identify the reaches that flow into "idCoast"
    ixFeed = where(toComid[fromComid_ix] eq idCoast, nFeed)
    if(nFeed gt 0)then begin

     ; get the indices of "feeder" reaches in the shapefile
     jxFeed = comId_topo_ix[ixFeed]

     ; sort the "feeder" reaches in terms of area
     ixArea = sort(shape_upsArea[jxFeed])
     kxFeed = jxFeed[reverse(ixArea)]  

     ; identify the coastline reach
     kxCoast = where(typeFlowline[jxFeed] eq 'Coastline', nCoastFeed)
     if(jxCoast lt nCoast-1 and nCoastFeed ne 1)then stop, 'expect one coastal element for all but the last segment'

     ; write data to the shapefiles
     for mxFeed=0,nFeed-1 do begin
      nxFeed = mxFeed + (nCoastFeed eq 0) ; add 1 where there is no coastline
      writeShapefile, typeLine, kxFeed[mxFeed], ixNewShape, comId_sh[kxFeed[mxFeed]], shapeFile_init, flowline_shapes
      writeAttributes, shapeFile_init, ixCoastMask, ixNewShape, nxFeed ; 0 = coastline, 1 = 1st trib, ...
      writeAttributes, shapeFile_init, ixUpsArea,   ixNewShape, shape_upsArea[kxFeed[mxFeed]] 
      ixNewShape = ixNewShape +1
     endfor 

     ; identify the coastline reach
     kxCoast = where(typeFlowline[jxFeed] eq 'Coastline', nCoastFeed)
     if(nCoastFeed gt 0)then begin

      ; save the upstream information
      nUps_Coast[jxCoast] = nFeed
      *(ups_struct[jxCoast]) = {upSegIds:comID_sh[kxFeed], upSegIndices:lindgen(nFeed)+ixNewShape-nFeed}
      ;print, 'idCoast, upSegIndices = ', idCoast, (*(ups_struct[jxCoast])).upSegIndices

      ; update coastal index/id
      ixCoast = jxFeed[kxCoast]
      idCoast = comId_sh[ixCoast[0]]

     ; check coastal element 
     endif else begin
      if(jxCoast lt nCoast-1)then stop, 'expect coastal element for all but the last segment'
     endelse

    endif     ; if there are feeder reaches
   
   endfor  ; looping through coastal segments

   ; connect Atlantic/Gulf coast
   if(nameRegion eq 'NE_01'  or $ 
      nameRegion eq 'MA_02'  or $
      nameRegion eq 'SA_03N' or $
      nameRegion eq 'SA_03S' or $
      nameRegion eq 'SA_03W' or $
      nameRegion eq 'MS_08'  or $
      nameRegion eq 'TX_12'     ) then begin

    ; get the starting ID for the next region (iRegion+1)
    idCoastStart = call_function('idCoastStart', nhdFiles[0,iRegion+1] + '_' + nhdFiles[1,iRegion+1])
    if(n_elements(idCoastStart) ne 1)then stop, 'expect just one coastal element'

    ; get any unassigned reaches in the next region
    idUnassigned = call_function('idUnassigned', nhdFiles[0,iRegion+1] + '_' + nhdFiles[1,iRegion+1])
    if(n_elements(idUnassigned) gt 1)then stop, 'expect no more than one unassigned elements'

    ; get the vector of ids
    idVec = idCoastStart
    if(nFeed gt 0)then idVec = [comID_sh[kxFeed], idVec]
    if(n_elements(idUnassigned) gt 0)then idVec = [idVec, idUnassigned]

    ; get the vector of indices
    nVec  = n_elements(idVec)
    ixVec = lindgen(nVec) + ixNewShape - nFeed

    ; save the final coastline element
    nUps_Coast[nCoast-1]    = nVec
    *(ups_struct[nCoast-1]) = {upSegIds:idVec, upSegIndices:ixVec}
    ;print, 'idCoast, upSegIndices = ', idCoast, (*(ups_struct[nCoast-1])).upSegIndices

   endif ; if Atlantic/Gulf coast

   ; add dangling reach to California
   if(nameRegion eq 'CA_18')then begin
    nUps_Coast[nCoast-1]    = n_elements(comID_sh[kxFeed])
    *(ups_struct[nCoast-1]) = {upSegIds:comID_sh[kxFeed], upSegIndices:ixNewShape - nFeed}
   endif
 
   ; *****
   ; * CONCATENATE DATA STRUCTURES FOR THE CONUS...
   ; **********************************************
   
   ; concatenate data structures
   if(firstPass eq 1)then begin
    conus_comIdCoast = comIdCoast                     ; id of a coastal flowline
    conus_huc8_Coast = huc8_Coast                     ; HUC8 id of a coastal flowline
    conus_nUps_Coast = nUps_Coast                     ; number of flowlines "upstream" of the coastal flowline
    conus_ups_struct = ups_struct                     ; vector of upstream ids/indices for each coastline flowline
    firstPass=0
   endif else begin
    conus_comIdCoast = [conus_comIdCoast, comIdCoast] ; id of a coastal flowline
    conus_huc8_Coast = [conus_huc8_Coast, huc8_Coast] ; HUC8 id of a coastal flowline
    conus_nUps_Coast = [conus_nUps_Coast, nUps_Coast] ; number of flowlines "upstream" of the coastal flowline
    conus_ups_struct = [conus_ups_struct, ups_struct] ; vector of upstream ids/indices for each coastline flowline
   endelse

   ; check
   ;stop, 'end of subregion' 

  endfor  ; looping through sub-regions
 endfor  ; looping through regions

 ; save data
 save, conus_comIdCoast, conus_huc8_Coast, conus_nUps_Coast, conus_ups_struct, filename=coastalSave_conus

; if the save file exists
endif else begin
 restore, coastalSave_conus
endelse

;stop, 'after coastal navigation'

; =============================================================================================
; =============================================================================================
; =============================================================================================
; =============================================================================================

; retrieve attributes from the shapefile
get_attributes, shapeFile_init, 'upsArea',   upsArea
get_attributes, shapeFile_init, 'idUnique',  idUnique
get_attributes, shapeFile_init, 'coastMask', coastMask

; get the coastline features
ixCoastal = where(coastMask eq 0, nCoastal)
print, nCoastal

; define Pfafstetter code
nShape   = n_elements(idUnique)
pCodeVec = strarr(nShape)

; *****
; * DEFINE THE 1ST-LEVEL PFAFSTETTER CODES...
; *******************************************

; identify the index of the coastline east of the Mississippi
; NOTE : the Mississippi is the only basin in the conus with one of the four North American main stems
idTest  = 22810603L
ixTest  = where(conus_comIdCoast eq idTest, nMatch)
if(nMatch ne 1)then stop, 'cannot find the Mississipi coast'
print, idTest, conus_comIdCoast[ixTest[0]]

; loop through features
for iFeature=0,nCoastal-1 do begin

 ; get the coastal element
 jFeature = ixCoastal[iFeature]

 ; define the region
 idRegion = conus_huc8_Coast[iFeature]/1000000L

 ; process the Mississippi (only basin in the conus with one of the four North American main stems)
 if(idRegion eq 08)then begin
  if(iFeature le ixTest[0])then pCode='7' else pCode='9' 
 
 ; process all other reaches
 endif else begin
  case idRegion of
   17 : pCode = '1'
   18 : pCode = '9'
   13 : pCode = '9'
   12 : pCode = '9'
   03 : pCode = '7'
   02 : pCode = '7'
   01 : pCode = '7'
   04 : pCode = '6'  ; St Lawrence River on the continental scale
   else: stop, 'cannot find region'
  endcase 
 endelse

 ; save the Pfafstetter code for the coastline
 pCodeVec[ixCoastal[iFeature]] = pCode

 ; save the Pfafstetter code for the tributaries
 if( (*(conus_ups_struct[iFeature])) ne !NULL )then begin
  nTrib = n_elements( (*(conus_ups_struct[iFeature])).upSegIndices )
  if(nTrib gt 0)then begin
   for ixTrib=0,nTrib-1 do begin
    jxTrib = (*(conus_ups_struct[iFeature])).upSegIndices[ixTrib]
    if(idUnique[jxTrib] ne (*(conus_ups_struct[iFeature])).upSegIds[ixTrib])then stop, 'id mismatch'
    if(coastMask[jxTrib] gt 0)then pCodeVec[jxTrib] = pCode
   endfor
  endif
 endif

 ; check
 if(idUnique[jFeature] ne conus_comIdCoast[iFeature])then stop, 'mismatch in coastal elements'
 ;print, iFeature, nCoastal, idUnique[jFeature], conus_comIdCoast[iFeature], conus_huc8_Coast[iFeature]
 ;if(iFeature eq 10)then stop

endfor  ; looping through features

; identify the index of the Mississippi itself
; NOTE : the Mississippi is the only basin in the conus with one of the four North American main stems
idTest  = 22811611L
ixTest  = where(idUnique eq idTest, nMatch)
if(nMatch ne 1)then stop, 'cannot find the Mississipi itself'
pCodeVec[ixTest[0]] = '8'

; define new shape file
shp_fileNew = base_filepath + 'nhdPlus_SHPs_coast/conusCoast_pfaf1.shp'

; copy shapefile
spawn, 'ogr2ogr ' + shp_fileNew + ' ' + shapeFile_init + ' 2> log.txt' ; copy initial shapefile to shp_fileNew

; define Pfafstetter code in shapefile
defineAttributes, shp_fileNew, 'pfafCode', 'character(30)', ixPfafCode  ; ixPfafCode = column in the file
writeAttributes,  shp_fileNew, ixPfafCode, lindgen(nShape), pCodeVec

; *****
; * DEFINE THE 2nd-LEVEL PFAFSTETTER CODES FOR THE COASTAL BASINS...
; ******************************************************************

; define the Pfafstetter codes
oldPfaf = fix(pCodeVec)
newPfaf = intarr(nShape)

; define inter-basins
tribBasins  = [2,4,6,8]
interBasins = [1,3,5,7,9]

; loop through the inter-basins in the first Pfafstetter level
for pfafOne=1,9,2 do begin

 ; get the subset of a given code
 ixSubset = where(oldPfaf[ixCoastal] eq pfafOne, nSubset)
 if(nSubset eq 0)then continue
 ;if(pfafOne ne 9)then continue

 ; identify major basins
 case pfafOne of   ;         2          4          6          8
     1: bigBasins = [23832907L,    -9999L,    -9999L,    -9999L]   ; Columbia, Fraser, Kuskokwim, Yukon
     7: bigBasins = [   -9999L,  4726685L,  2297884L, 18524217L]   ; St. John, Susquehanna, Apalachicola, Mobile
     9: bigBasins = [  626220L,    -9999L,    -9999L,  2788603L]   ; Rio Grande, La Pescadora, Colorado, Sacramento
  else: stop, 'do not expect inter-basin 3 or 5 (both are in northern Canada)'
 endcase

 ; define starting Pfafstetter index
 jxTrib    = 0
 ixTrib    = where(bigBasins gt 0, nTrib)
 desireId  = bigBasins[ixTrib[jxTrib]]
 pfafTrib  = tribBasins[ixTrib[jxTrib]]
 pfafInter = interBasins[ixTrib[jxTrib]]

 ; loop through features
 for iFeature=0,nSubset-1 do begin

  ; get the coastal element
  jFeature = ixSubset[iFeature]     ; index in the coastal vector
  kFeature = ixCoastal[jFeature]    ; index in the shapefile vector
  if(conus_comIdCoast[jFeature] ne idUnique[kFeature])then stop, 'mismatch in coastal element'

  ; assign the Pfafstetter code for the coastal element
  newPfaf[kFeature] = pfafInter
  ;print, conus_comIdCoast[jFeature], pfafTrib, pfafInter

  ; check if there is anything upstream
  if((*(conus_ups_struct[jFeature])) ne !NULL)then begin

   ; check if there are tributaries upstream
   kxTrib = (*(conus_ups_struct[jFeature])).upSegIndices
   iMatch = where(coastMask[kxTrib] gt 0, nMatch)
   if(nMatch gt 0)then begin

    ; update pfaf Code if the upstream id matches the desired trib
    ixFirstReach = kxTrib[iMatch[0]]  ; the first reach in the trib vector
    if(idUnique[ixFirstReach] eq desireId)then begin
     newPfaf[ixFirstReach] = pfafTrib
     jxTrib = jxTrib+1
     if(jxTrib lt nTrib)then begin
      desireId  = bigBasins[ixTrib[jxTrib]]
      pfafTrib  = tribBasins[ixTrib[jxTrib]]
      pfafInter = interBasins[ixTrib[jxTrib]]
     endif else begin
      desireId  = -9999 
      pfafTrib  = -9999
      pfafInter = pfafInter+2
     endelse
  
    ; assign the pfaf Code to the trib
    endif else begin ; if the upstream id matches the desired trib
     if(total(oldPfaf[kxTrib[iMatch]] mod 2, /integer) gt 0)then begin
      newPfaf[kxTrib[iMatch]] = pfafInter
     endif else begin
      newPfaf[kxTrib[iMatch]] = 0
     endelse
    endelse

   endif   ; if there are upstream tributaries
  endif   ; if upstream indices are valid

  ; check
  ;if(jxTrib gt 0)then stop, 'check'

 endfor  ; looping through features

endfor  ; looping through major interbasins

; identify the coastline west of the Rio Grande (before the continent gap)
idTest  = 943090473L
ixTest  = where(idUnique eq idTest, nMatch)
if(nMatch ne 1)then stop, 'cannot find the coastline west of the Rio Grande'
newPfaf[ixTest[0]] = 3

; *****
; * DEFINE THE 2nd-LEVEL PFAFSTETTER CODES FOR THE GREAT LAKES...
; ***************************************************************

; get the subset of a given code
pfafOne  = 6  ; Great Lakes
ixSubset = where(oldPfaf[ixCoastal] eq pfafOne, nSubset)
if(nSubset eq 0)then stop, 'expect elements in the Great Lakes'

; define lake
pfafLake = 2

; loop through features
for iFeature=0,nSubset-1 do begin

 ; get the coastal element
 jFeature = ixSubset[iFeature]     ; index in the coastal vector
 kFeature = ixCoastal[jFeature]    ; index in the shapefile vector
 if(conus_comIdCoast[jFeature] ne idUnique[kFeature])then stop, 'mismatch in coastal element'

 ; assign the Pfafstetter code for the coastal element
 newPfaf[kFeature] = pfafLake

 ; check if there is anything upstream
 if((*(conus_ups_struct[jFeature])) ne !NULL)then begin

  ; assign the Pfafstetter code to tributaries upstream
  kxTrib = (*(conus_ups_struct[jFeature])).upSegIndices
  iMatch = where(coastMask[kxTrib] gt 0, nMatch)
  if(nMatch gt 0)then newPfaf[kxTrib[iMatch]] = pfafLake

 ; nothing upstream = move to the new lake
 endif else begin
  pfafLake = pfafLake+2
 endelse

endfor  ; looping through features

; (intermediate test)

; define new shape file
shp_fileNew = base_filepath + 'nhdPlus_SHPs_coast/conusCoast_pfaf2.shp'

; copy shapefile
spawn, 'ogr2ogr ' + shp_fileNew + ' ' + shapeFile_init + ' 2> log.txt' ; copy initial shapefile to shp_fileNew

; save the pfafstetter code
pCodeVec = strtrim(oldPfaf*10 + newPfaf, 2) 

; define Pfafstetter code in shapefile
defineAttributes, shp_fileNew, 'pfafCode', 'character(30)', ixPfafCode  ; ixPfafCode = column in the file
writeAttributes,  shp_fileNew, ixPfafCode, lindgen(nShape), pCodeVec

; *****
; * DEFINE PFAFSTETTER CODES FOR ALL OTHER LEVELS...
; **************************************************

; define the maximum number of levels
maxLevel = 19  ; cannot have numbers with more than 19 digits

; define the number of upstream elements
nUpstream = replicate(0L, nShape)
nUpstream[ixCoastal] = conus_nUps_Coast

; define the upstream reach structure
upsReach = ptrarr(nShape, /allocate_heap)
upsReach[ixCoastal] = conus_ups_struct

; loop through the first two levels
for pfafOne=1,9 do begin
 for pfafTwo=1,9 do begin

  ; test
  ;if(pfafOne ne 9)then continue
  ;if(pfafTwo ne 1)then continue

  ; get the subset for the desired Pfafstetter codes
  ixSubset = where(oldPfaf eq pfafOne and newPfaf eq pfafTwo, nSubset)
  if(nSubset le 1)then continue ; ignore big basin tribs

  ; print status 
  print, 'pfafOne = ', pfafOne, '; pfafTwo = ', pfafTwo, '; nSubset = ', nSubset

  ; get the coastal subset
  iyCoastal = where(oldPfaf[ixCoastal] eq pfafOne and newPfaf[ixCoastal] eq pfafTwo, mCoastal)
  if(mCoastal eq 0)then stop, 'expect some coastal elements in the subset'
  
  ; get the vector to look up the elements in the subset structure
  ixLookup = replicate(-9999L, nShape)
  ixLookup[ixSubset] = lindgen(nSubset)

  ; define the conus subset vectors
  nUpstream_subset = replicate(0L, nSubset)
  upsReach_subset  = ptrarr(nSubset, /allocate_heap)
  idUnique_subset  = idUnique[ixSubset]
  upsArea_subset   = upsArea[ixSubset] 

  ; initialize coastal counter
  iCounter = 0  ; index of coastal elements

  ; replace the indices to point to correct elements in the subset vectors
  for iFeature=0,nSubset-1 do begin

   ; get subset index
   jFeature = ixSubset[iFeature]  ; index in the shapefile vector

   ; check if it is a coastal element
   if(coastMask[jFeature] eq 0)then begin

    ; find the index in the coastal vector
    kFeature = iyCoastal[iCounter]
    iCounter = iCounter+1

    ; check if the feature is at end of the coastline
    if(iFeature eq nSubset-1)then begin
     if((*conus_ups_struct[kFeature]) eq !NULL)then begin
      nUpstream_subset[iFeature]   = 0
      (*upsReach_subset[iFeature]) = !NULL
      break
     endif
    endif 
 
    ; check that everything is as it should be
    if(idUnique[jFeature] ne conus_comIdCoast[kFeature])then stop, 'cannot find coastal element'
    if((*conus_ups_struct[kFeature]) eq !NULL)then stop, 'expect upstream elements at the coast'

    ; get the upstream indices in the original vector
    idUps = (*conus_ups_struct[kFeature]).upSegIds      ; reach ids
    ixUps = (*conus_ups_struct[kFeature]).upSegIndices  ; indices in the full vector
    jxUps = ixLookup[ixUps]                             ; indices in the subset vector

    ; check for the upstream indices in the current Pfafstetter subset
    ixValid = where(oldPfaf[ixUps] eq pfafOne and newPfaf[ixUps] eq pfafTwo, nValid)
    if(nValid gt 0)then begin

     ; save the upstream structure
     nUpstream_subset[iFeature]   = nValid
     (*upsReach_subset[iFeature]) = {upSegIds:idUps[ixValid], upSegIndices:jxUps[ixValid]}

     ; check
     for iUps=0,nValid-1 do begin
      iTest = ixUps[ixValid[iUps]]
      jTest = jxUps[ixValid[iUps]]
      if(jTest eq -9999L)then stop, 'expect a valid index'
      if(idUnique_subset[jTest] ne idUnique[iTest])then stop, 'mismatched id in subset'
     endfor

    endif  ; if in the correct Pfafsttter subset
   endif ; if a coastal element

  endfor  ; looping through features

  ; define the level
  nLevel = 2        ; (first two Pfafstetter codes are already assigned)
  iLevel = nLevel-1

  ; define the pfafstetter code
  mainStem = replicate(0L,  maxLevel,nSubset)
  pfafVec  = replicate(0LL, nSubset)

  ; define the initial Pfafsttter code
  pCode = [pfafOne, pfafTwo, replicate(0L, maxLevel-2)]

  ; get the index of the first reach
  ixStart = 0

  ; get the Pfafstetter codes for all reaches in a given coastal segment
  ; input:
  ;  iLevel           (integer)   : start index of Pfafstetter level
  ;  ixStart          (integer)   : start index in the shapefile vector
  ;  pCode            (int vec)   : vector of pfafstetter indices
  ;  idUnique_subset  (int vec)   : id of each reach
  ;  nUpstream_subset (int vec)   : number of reaches upstream of each reach
  ;  upsReach_subset  (structure) : indices of upstream reaches
  ;  upsArea_subset   (real vec)  : upstream area above each reach
  ;
  ; output:
  ;  mainStem         (int array) : pfafstetter code for each level
  ;  pfafVec          (int vec)   : pfafstetter code
  danglePfafstetter, iLevel, ixStart, pCode, idUnique_subset, nUpstream_subset, upsReach_subset, upsArea_subset, $  ; input
                     mainStem, pfafVec ; output

  ; get the string
  for iSubset=0,nSubset-1 do begin
   jSubset = ixSubset[iSubset]
   strTemp = strjoin(strtrim(mainstem[*,iSubset],2))
   pCodeVec[jSubset] = strmid(strTemp, 0, strpos(strTemp, '0') )
   ;print, pCodeVec[jSubset], ' : ', strTemp
  endfor

  ; remove duplicates
  ixCheck  = replicate(0,nSubset)
  for iSubset=0,nSubset-1 do begin
   jSubset = ixSubset[iSubset]
   if(ixCheck[iSubset] eq 0)then begin
    ixDuplicate = where(pCodeVec[jSubset] eq pCodeVec[ixSubset], nDuplicate)
    if(nDuplicate gt 1)then begin

     ; define Pfafstetter code
     case 1 of
      (nDuplicate gt   0) and (nDuplicate le   5): pCode = indgen(min([nDuplicate,5]))*2+1
      (nDuplicate gt   5) and (nDuplicate le  25): pCode = pLev2[0:nDuplicate-1]
      (nDuplicate gt  25) and (nDuplicate le 125): pCode = pLev3[0:nDuplicate-1]
      (nDuplicate gt 125) and (nDuplicate le 625): pCode = pLev4[0:nDuplicate-1]
      else: stop, 'expect less than 625 duplicates'
     endcase
     
     ; update vectors
     pCodeVec[ixSubset[ixDuplicate]] = pCodeVec[ixSubset[ixDuplicate]] + strtrim(pCode,2)
     ixCheck[ixDuplicate] = 1

    endif   ; if duplicates
   endif   ; if not processed

   ; check
   ;print, iSubset, ' - ', pCodeVec[jSubset], ' : ', strjoin(strtrim(mainstem[*,iSubset],2))

  endfor  ; looping through subset
  
  ;stop, 'stop: after danglePfafstetter'

 endfor ; 2nd Pfafstetter level
endfor ; 1st Pfafstetter level

; define new shape file
shp_fileNew = base_filepath + 'nhdPlus_SHPs_coast/conusCoast_pfaf-all.shp'

; copy shapefile
spawn, 'ogr2ogr ' + shp_fileNew + ' ' + shapeFile_init + ' 2> log.txt' ; copy initial shapefile to shp_fileNew

; define Pfafstetter code in shapefile
defineAttributes, shp_fileNew, 'pfafCode', 'character(30)', ixPfafCode  ; ixPfafCode = column in the file
writeAttributes,  shp_fileNew, ixPfafCode, lindgen(nShape), pCodeVec

stop
end

; ===================================================================
; ===================================================================

; get the vector of unassigned tributaries at region boundaries
function idUnassigned, nameRegion

case nameRegion of
 'NE_01' :  idVec = !NULL
 'MA_02' :  idVec = !NULL
 'SA_03N':  idVec = [ 10466473L ]
 'SA_03S':  idVec = [ 14353046L ]
 'SA_03W':  idVec = !NULL
 'MS_08' :  idVec = [ 15714785L ]
 'TX_12' :  idVec = [ 24719331L ]
 'RG_13' :  idVec = !NULL
 'CA_18' :  idVec = !NULL
 'PN_17' :  idVec = !NULL
 'GL_04' :  idVec = !NULL
 else: stop, 'idUnassigned: unknown region'
endcase

return, idVec


end

; ===================================================================
; ===================================================================

; get the vector of starting IDs for a given region
function idCoastStart, nameRegion

; define the first coastal segment...
case nameRegion of
 'NE_01' :  idVec = [166174043L]
 'MA_02' :  idVec = [  6242071L]
 'SA_03N':  idVec = [ 10466691L]
 'SA_03S':  idVec = [ 14352952L]
 'SA_03W':  idVec = [ 10318136L]
 'MS_08' :  idVec = [167578939L]
 'TX_12' :  idVec = [  1477701L]
 'RG_13' :  idVec = [943090472L]
 'CA_18' :  idVec = [ 20324645L]
 'PN_17' :  idVec = [ 23949489L]
 'GL_04' :  idVec = [  4795268L, 12210398L, 166764010L, 166766843L] ; Superior, Michigan, Erie, Ontario
 else: stop, 'idCoastStart: unknown region'
endcase

return, idVec

end
