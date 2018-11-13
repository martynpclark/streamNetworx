pro navigateCoastline

; Used to navigate the coastline
;  - purpose: assign Pfaffstetter codes to dangling reaches

; Define base path
shp_rootpath = '/Volumes/d1/mclark/NHD_Plus/ancillary_data/'

; Define shapefiles for coastal regions
nhdFiles = [$
            ['PN','17' ], $
            ['CA','18' ], $
            ['RG','13' ], $
            ['TX','12' ], $
            ['MS','08' ], $
            ['SA','03W'], $ 
            ['SA','03S'], $ 
            ['SA','03N'], $ 
            ['MA','02' ], $
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

; loop through shapefiles
for iFile=0,n_elements(nhdFiles)/2-1 do begin

 ; *****
 ; * GET STREAM SEGMENTS...
 ; ************************

 ; get filename
 shp_rootpath   = '/Volumes/d1/mclark/NHD_Plus/ancillary_data/nhdPlus_raw/'
 shp_filepath    = shp_rootpath  + 'NHDPlus'+nhdFiles[0,iFile] + '/NHDPlus'+nhdFiles[1,iFile]
 seg_filename    = shp_filepath + '/NHDSnapshot/Hydrography/NHDFlowline'
 link_filename   = shp_filepath + '/NHDPlusAttributes/PlusFlow'

 ; get the desired attributes from the flow lines
 get_attributes, seg_filename+'.dbf', 'COMID',     comId_sh
 get_attributes, seg_filename+'.dbf', 'REACHCODE', reachCharacter

 ; get the linkages
 get_attributes, link_filename+'.dbf', 'FROMCOMID', fromComid
 get_attributes, link_filename+'.dbf', 'TOCOMID',   toComid

 ; get the number of shapes
 nShapes = n_elements(comId_sh)

 ; *****
 ; * GET SUBSET OF DANGLING REACHES IN A SPECIFIC REGION...
 ; ********************************************************
 
 ; define unique string for save files
 nameRegion = nhdFiles[0,iFile] + '_' + nhdFiles[1,iFile]
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
 matchName = savePath + 'matchTopo_nhdPlusRaw' + nameRegion + '.sav'
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
 ; * NAVIGATE THE COASTLINE...
 ; ***************************

 ; define "dangling" reaches that touch the coast
 ixDangle = where(downSegId[segId_mizu_ix] le 0, nDangle)
 iyDangle = comID_sh_ix[ixDangle]  ; indices of dangling reaches in the shapefile

 ; identify ids of downstream flowlines from the dangling reaches
 idFlowline = shape_toComID[iyDangle] 

 ; define arrays for the dangling reaches
 dangleFrom = replicate(-9999L, nDangle)
 dangleToId = replicate(-9999L, nDangle)
 dangleHUC8 = replicate(-9999L, nDangle)
 dangleArea = replicate(-9999d, nDangle)

 ; define the first coastal segment...
 case nameRegion of
  'PN_17' : idCoastStart =  24534566L
  'CA_18' : idCoastStart =  24680675L
  'RG_13' : idCoastStart = 943090472L
  'TX_12' : idCoastStart =    207867L
  'MS_08' : idCoastStart =   3712026L
  'SA_03W': idCoastStart =  27139762L
  'SA_03S': idCoastStart =  10318146L
  'SA_03N': idCoastStart =   6322139L
  'MA_02':  idCoastStart =   9889028L
  'NE_01':  idCoastStart =  25077422L
  else: stop, 'unknown region'
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
  ;if(nameRegion eq 'SA_03W')then print, 'idCoast = ', idCoast

  ; identify the dangling reaches
  ixFeed = where(idFlowline eq idCoast, nFeed)
  if(nFeed ge 1)then begin
   dangleToId[ixFeed] = idCoast 
   dangleFrom[ixFeed] = segId_mizu[segId_mizu_ix[ixDangle[ixFeed]]]
   dangleArea[ixFeed] = totalArea_mizu[segId_mizu_ix[ixDangle[ixFeed]]]
   dangleHUC8[ixFeed] = long(strmid(reachCharacter[comID_sh_ix[ixDangle[ixFeed]]], 0, 8))
   if(dangleFrom[ixFeed[0]] eq 22811611L)then print, 'Mississippi'
  endif


  ; get the next coastal segment
  ixCoast = where(comId_sh eq shape_toComID[ixCoast[0]], nMatch)
  idCoast = comId_sh[ixCoast[0]]
  nCoast  = nCoast+1

 endwhile

 ; ========================================================================================

 ; special case of the Sabine River in Texas (reaches the coast in Louisiana)
 if(nameRegion eq 'TX_12')then begin

  ; comId for the Sabine
  idTest = 24719331L

  ; downstream ID for the Sabine
  ixTest = where(fromComid eq idTest, nMatch) 
  downId = toComId[ ixTest[0] ]

  ; area/HUC8 of the Sabine
  ixTest = where(segId_mizu[segId_mizu_ix] eq idTest, nMatch) 
  xArea  = totalArea_mizu[segId_mizu_ix[ixTest[0]]]
  xHUC8  = long(strmid(reachCharacter[comID_sh_ix[ixTest[0]]], 0, 8))  
  print, 'Sabine: downId, xArea, xHUC8 = ', downId, xArea, xHUC8

  ; update vectors
  dangleFrom = [dangleFrom, idTest]
  dangleToId = [dangleToId, downId]
  dangleArea = [dangleArea, xArea]
  dangleHUC8 = [dangleHUC8, xHUC8]

 endif

 ; ========================================================================================

 ; special case of the Altamaha River in Georgia (in SA_3S, reaches the coast SA_3N)
 if(nameRegion eq 'SA_03S')then begin

  ; comId for the Altamaha
  idTest = 14353046LL

  ; downstream ID for the Sabine
  ixTest = where(fromComid eq idTest, nMatch) 
  downId = toComId[ ixTest[0] ]

  ; area/HUC8 of the Sabine
  ixTest = where(segId_mizu[segId_mizu_ix] eq idTest, nMatch) 
  xArea  = totalArea_mizu[segId_mizu_ix[ixTest[0]]]
  xHUC8  = long(strmid(reachCharacter[comID_sh_ix[ixTest[0]]], 0, 8))  
  print, 'Altamaha: downId, xArea, xHUC8 = ', downId, xArea, xHUC8

  ; update vectors
  dangleFrom = [dangleFrom, idTest]
  dangleToId = [dangleToId, downId]
  dangleArea = [dangleArea, xArea]
  dangleHUC8 = [dangleHUC8, xHUC8]

 endif

 ; ========================================================================================

 ; special case of the Pearl River in Louisiana (reaches the coast in Mississippi)
 if(nameRegion eq 'MS_08')then begin

  ; comId for the Sabine
  idTest = 15714785LL

  ; downstream ID for the Sabine
  ixTest = where(fromComid eq idTest, nMatch) 
  downId = toComId[ ixTest[0] ]

  ; area/HUC8 of the Sabine
  ixTest = where(segId_mizu[segId_mizu_ix] eq idTest, nMatch) 
  xArea  = totalArea_mizu[segId_mizu_ix[ixTest[0]]]
  xHUC8  = long(strmid(reachCharacter[comID_sh_ix[ixTest[0]]], 0, 8))  
  print, 'Pearl: downId, xArea, xHUC8 = ', downId, xArea, xHUC8

  ; update vectors
  dangleFrom = [dangleFrom, idTest]
  dangleToId = [dangleToId, downId]
  dangleArea = [dangleArea, xArea]
  dangleHUC8 = [dangleHUC8, xHUC8]

 endif

 ; ========================================================================================

 ; save the coastal links
 if(iFile eq 0)then begin
  conus_huc8_Coast = huc8_Coast
  conus_comIDCoast = comIdCoast
  conus_dangleToId = dangleToId  
  conus_dangleFrom = dangleFrom  
  conus_dangleArea = dangleArea  
  conus_dangleHUC8 = dangleHUC8  
 endif else begin
  conus_huc8_Coast = [conus_huc8_Coast,huc8_Coast]
  conus_comIDCoast = [conus_comIDCoast,comIdCoast]
  conus_dangleToId = [conus_dangleToId,dangleToId]  
  conus_dangleFrom = [conus_dangleFrom,dangleFrom]  
  conus_dangleArea = [conus_dangleArea,dangleArea]  
  conus_dangleHUC8 = [conus_dangleHUC8,dangleHUC8]  
 endelse

endfor  ; looping through regions

; *****
; * DEFINE AND WRITE NETCDF FILE... 
; *********************************

; get the size of the vectors
nCoast  = n_elements(conus_comIDCoast)
nDangle = n_elements(conus_dangleToId)

; define filename
nc_filename = nc_filepath + 'navigateCoast.nc'

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

; write variables
ncdf_varput, ncid, varid_huc8_Coast, conus_huc8_Coast
ncdf_varput, ncid, varid_comIDCoast, conus_comIDCoast
ncdf_varput, ncid, varid_dangleToId, conus_dangleToId
ncdf_varput, ncid, varid_dangleFrom, conus_dangleFrom
ncdf_varput, ncid, varid_dangleArea, conus_dangleArea
ncdf_varput, ncid, varid_dangleHUC8, conus_dangleHUC8

; close file
ncdf_close, ncid 

stop
end
