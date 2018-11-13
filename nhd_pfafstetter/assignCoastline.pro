pro assignCoastline

; Used to navigate the coastline and assign Pfafstetter codes to coastline segments

; define path for .sav files
savePath = '/Volumes/d1/mclark/NHD_Plus/ancillary_data/idlSave/'

saveName = savePath + 'pfafShapefiles.sav'
spawn, 'rm ' + saveName
if(file_test(saveName) eq 0)then begin

 ; *****
 ; * READ THE MIZUROUTE NETWORK... 
 ; *******************************
 
 ; define the NetCDF file
 nc_filepath = '/Volumes/d1/mclark/NHD_Plus/ancillary_data/'
 nc_filename = nc_filepath + 'NHDPlus2_updated-CONUS.nc'
 print, 'Reading ancillary file'
 
 ; get the segid
 nc_file = ncdf_open(nc_filename, /nowrite)
  ivar_id = ncdf_varid(nc_file,'link')
  ncdf_varget, nc_file, ivar_id, segId_mizu
 ncdf_close, nc_file
 
 ; *****
 ; * DEFINE SHAPEFILES... 
 ; **********************
 
 ; define named variables
 ixCoastal  = '1001'
 ixInterior = '1002'
 
 ; Define shapefiles
 nhdFiles = [$
 			['PN','17' ,ixCoastal ], $
 			['CA','18' ,ixCoastal ], $
 			['RG','13' ,ixCoastal ], $
 			['TX','12' ,ixCoastal ], $
 			['MS','08' ,ixCoastal ], $
 			['SA','03W',ixCoastal ], $
 			['SA','03S',ixCoastal ], $
 			['SA','03N',ixCoastal ], $
 			['MA','02' ,ixCoastal ], $
 			['NE','01' ,ixCoastal ], $
 			['GL','04' ,ixCoastal ], $
 			['CO','14' ,ixInterior], $
 			['CO','15' ,ixInterior], $
 			['GB','16' ,ixInterior], $
 			['MS','05' ,ixInterior], $
 			['MS','06' ,ixInterior], $
 			['MS','07' ,ixInterior], $
 			['MS','10L',ixInterior], $
 			['MS','10U',ixInterior], $
 			['MS','11' ,ixInterior], $
 			['SR','09' ,ixInterior]  ]
 
 ; loop through shapefiles
 for iFile=0,n_elements(nhdFiles)/3-1 do begin
 
  ; *****
  ; * READ SHAPEFILES...
  ; ********************
 
  ; define unique string for save files
  nameRegion = nhdFiles[0,iFile] + '_' + nhdFiles[1,iFile]
  print, 'Processing ', nameRegion
 
  ; define the flowline shapefile
  shp_path = '/Volumes/d1/mclark/NHD_Plus/ancillary_data/nhdPlus_SHPs_pfaf/'
  seg_file = shp_path + 'Flowline_' + nameRegion + '.shp'
  cat_file = shp_path + 'Catchment_' + nameRegion + '.shp'
 
  ; define the linkage shapefile
  shp_rootpath  = '/Volumes/d1/mclark/NHD_Plus/ancillary_data/nhdPlus_raw/'
  shp_filepath  = shp_rootpath  + 'NHDPlus'+nhdFiles[0,iFile] + '/NHDPlus'+nhdFiles[1,iFile]
  link_filename = shp_filepath + '/NHDPlusAttributes/PlusFlow.dbf'
 
  ; get the desired attributes from the flow lines
  print, 'Reading '+seg_file
  get_attributes, seg_file, 'COMID',     comId_seg
  get_attributes, seg_file, 'FTYPE',     flowlineType
  get_attributes, seg_file, 'PFAF_CODE', pfafCode_seg
  print, 'maximum code = ', max(long(strmid(strtrim(pfafCode_seg,2),0,2)))
 
  ; get the desired attributes from the linkages
  print, 'Reading '+link_filename
  get_attributes, link_filename, 'FROMCOMID', fromComid
  get_attributes, link_filename, 'TOCOMID',   toComid
 
  ; get the number of shapes
  nSeg = n_elements(comId_seg)
 
  ; match the downstream links
  matchName = savePath + 'matchNetworkTopo_' + nameRegion + '.sav'
  if(file_test(matchName) eq 0)then begin
   print, 'Matching the file ' + matchName
   match, comId_seg, fromComid, comId_topo_ix, fromComid_ix
   save, comId_topo_ix, fromComid_ix, filename=matchName
  endif else begin
   restore, matchName
  endelse
 
  ; identify the downstream link
  shape_toComID = replicate(-9999L, nSeg)
  shape_toComID[comId_topo_ix] = toComid[fromComid_ix]
 
  ; identify the coastal segments
  ixCoastline = where(flowlineType eq 'Coastline', nCoastline)
 
  ; identify the type of the downstream segment
  print, 'Identifying the downstream flow type'
  shape_typeLine = replicate('unknown', nSeg)
  for iShape=0,nSeg-1 do begin
   if(shape_toComID[iShape] gt 0)then begin
    ixMatch = where(shape_toComID[iShape] eq comId_seg[ixCoastline], nMatch)
    if(nMatch eq 1)then shape_typeLine[iShape] = flowlineType[ixCoastline[ixMatch[0]]]
   endif
  endfor
 
  ; identify the coastline
  izDangle = replicate(0, nSeg)
  iyDangle = where(flowlineType ne 'Coastline' and shape_typeLine eq 'Coastline', nDangle)
  if(nDangle gt 0)then izDangle[iyDangle] = 1
 
  ; *****
  ; * ASSIGN PFAFSTETTER CODES TO COASTAL FLOWLINES...
  ; **************************************************
 
  ; check if there is a coastline
  if(nCoastline gt 0)then begin
 
   ; check
   if(nhdFiles[2,iFile] eq ixInterior)then stop, 'do not expect coastlines for an interior basin'
 
   ; define the first coastal segment...
   case nameRegion of
    'PN_17' : idCoastStart = [ 24534588LL]
    'CA_18' : idCoastStart = [ 24680675LL]
    'RG_13' : idCoastStart = [943090472LL]
    'TX_12' : idCoastStart = [   207867LL]
    'MS_08' : idCoastStart = [  3712026LL]
    'SA_03W': idCoastStart = [ 27139762LL]
    'SA_03S': idCoastStart = [ 10318146LL]
    'SA_03N': idCoastStart = [  6322139LL]
    'MA_02':  idCoastStart = [  9889028LL]
    'NE_01':  idCoastStart = [ 25077422LL]
    'GL_04':  idCoastStart = [904020522LL, 904080119LL, 30833992LL, 25374297LL]
    else: stop, 'unknown region'
   endcase
 
   ; loop through coastal regions
   for numCoasts=0,n_elements(idCoastStart)-1 do begin
 
    ; initialize the coastal element
    idCoast = idCoastStart[numCoasts]
    ixCoast = where(comId_seg[ixCoastline] eq idCoast, nMatch)
    iyCoast = ixCoastline[ixCoast]
    isItNew = 1
    nCoast  = 0
    ;print, 'iyCoast, idCoast = ', iyCoast[0], idCoast
    
    ; get a long vector to add to the base
    ix = replicate(1,5)*10 + indgen(5)*2 + 1
    for i=3,9,2 do ix = [ix, replicate(i,5)*10 + indgen(5)*2 + 1]
    iy = ix+100
    for j=3,9,2 do begin
 	ix = replicate(1,5)*10 + indgen(5)*2 + 1
 	for i=3,9,2 do ix = [ix, replicate(i,5)*10 + indgen(5)*2 + 1]
 	iy = [iy, ix+j*100]
    endfor
    iy = reverse(iy)
    ;print, 'iy = ', iy
    
    ; get a longer vector to add to the base
    iz = [iy+9000, iy+7000, iy+5000, iy+3000, iy+1000]
    
    ; get a short vector to add to the base
    ix = replicate(1,5)*10 + indgen(5)*2 + 1
    for i=3,9,2 do ix = [ix, replicate(i,5)*10 + indgen(5)*2 + 1]
    ix = reverse(ix)
    
    ; navigate the coastline
    print, 'Assign pfafsttter codes to coastal flowlines...'
    while (iyCoast[0] gt 0 and nMatch eq 1) do begin
    
 	; assign new reaches
 	if(isItNew eq 1)then begin
 	 ixAssign = iyCoast
 	 isItNew  = 0
 	endif else begin
 	 ixAssign = [ixAssign, iyCoast]
 	endelse
    
 	; identify the dangling reaches
 	ixFeed = where(shape_toComID[iyDangle] eq idCoast, nFeed)
 	if(nFeed ge 1)then begin
 	 for iFeed=0,nFeed-1 do begin
    
 	  ; get string of codes
 	  tempCode = strtrim(pfafCode_seg[iyDangle[ixFeed[iFeed]]], 2)
 	  tempVec  = replicate(0, strlen(tempCode) )
 	  reads, tempCode, tempVec, format='(20(i1))'
 	  ;print, 'pfafCode = ', tempCode
 	  ;print, 'pfafVec  = ', tempVec 
    
 	  ; check not a closed basin
 	  if(min(tempVec) eq 0)then continue
    
 	  ; skip weird: PNW
 	  if(tempCode eq '137571'     )then continue
 	  if(tempCode eq '13377511'   )then continue
 	  if(tempCode eq '13377373'   )then continue
 	  if(tempCode eq '133773559'  )then continue
 	  if(tempCode eq '1337733753' )then continue
 	  if(tempCode eq '133773317'  )then continue
 	  if(tempCode eq '131193'     )then continue
    
 	  ; skip weird: CA
 	  if(tempCode eq '99993'      )then continue
 	  if(tempCode eq '99717'      )then continue
 	  if(tempCode eq '99713'      )then continue
 	  if(tempCode eq '9939951'    )then continue
 	  if(tempCode eq '9795739997' )then continue
 	  if(tempCode eq '97957399951')then continue
 	  if(tempCode eq '9795739953' )then continue
 	  if(tempCode eq '97759917'   )then continue
 	  if(tempCode eq '975977'     )then continue
    
 	  ; skip weird: TX
 	  if(tempCode eq '9191113'      )then continue
 	  if(tempCode eq '919111'       )then continue
 	  if(tempCode eq '9157553'      )then continue
 	  if(tempCode eq '91551151'     )then continue
    
 	  ; skip weird: MS
 	  if(tempCode eq '913153'       )then continue
 	  if(tempCode eq '911375'       )then continue
 	  if(tempCode eq '79955'        )then continue
    
 	  ; skip weird: SA W
 	  if(tempCode eq '79135'        )then continue
 	  if(tempCode eq '773135'       )then continue
 	  if(tempCode eq '77199991'     )then continue
 	  if(tempCode eq '7599511'      )then continue
    
 	  ; skip weird: SA S
 	  if(tempCode eq '7599319973'   )then continue
 	  if(tempCode eq '75991915'     )then continue
 	  if(tempCode eq '75979933'     )then continue
 	  if(tempCode eq '759779751793' )then continue
 	  if(tempCode eq '75913713'     )then continue
    
 	  ; skip weird: SA N
 	  if(tempCode eq '757371'       )then continue
 	  if(tempCode eq '75733'        )then continue
 	  if(tempCode eq '7571371'      )then continue
 	  if(tempCode eq '75711793'     )then continue
 	  if(tempCode eq '75711771'     )then continue
 	  if(tempCode eq '7539315'      )then continue
 	  if(tempCode eq '7537113'      )then continue
 	  if(tempCode eq '7535753'      )then continue
 	  if(tempCode eq '75331711'     )then continue
 	  if(tempCode eq '7533157591'   )then continue
 	  if(tempCode eq '753315755'    )then continue
 	  if(tempCode eq '75331575371'  )then continue
 	  if(tempCode eq '7533157533'   )then continue
 	  if(tempCode eq '7533157511'   )then continue
 	  if(tempCode eq '7533157173'   )then continue
 	  if(tempCode eq '7533157139'   )then continue
 	  if(tempCode eq '7533157137'   )then continue
    
 	  ; skip weird: MA
 	  if(tempCode eq '7399139'      )then continue
 	  if(tempCode eq '7391997591'   )then continue
 	  if(tempCode eq '739197375'    )then continue
 	  if(tempCode eq '735977553'    )then continue
 	  if(tempCode eq '7359753'      )then continue
 	  if(tempCode eq '73591197'     )then continue
    
 	  ; skip weird: NE
 	  if(tempCode eq '73551195'     )then continue
 	  if(tempCode eq '73373553931'  )then continue
 	  if(tempCode eq '733733931'    )then continue
 	  if(tempCode eq '7333173'      )then continue
 	  if(tempCode eq '7331131'      )then continue
    
 	  ; get base ID
 	  strNew = strjoin(strtrim(tempVec mod 2, 2))
 	  if(nameRegion eq 'GL_04')then begin
 	   if(strlen(strNew) le 2)then stop, 'short string in the Great Lakes'
 	   ixBase = strpos(strmid(strNew,2), '0')+2
 	  endif else begin
 	   ixBase = strpos(strmid(strNew,0), '0')+0
 	  endelse
 	  if(ixBase eq -1)then stop, 'cannot identify an even numbered tributary'
 	  idBase = long64(strmid(tempCode, 0, ixBase+1))
 	  ;print, 'idBase = ', idBase
   
 	  ; assign codes
 	  isItNew = 1
 	  nAssign = n_elements(ixAssign)
 	  case 1 of
 	   (nAssign le   5):                      newCodes = 100LL*(idBase+1) + reverse(lindgen(nAssign))*2+1
 	   (nAssign gt   5) and (nAssign le  25): newCodes = 1000LL*(idBase+1) + ix[0:nAssign-1]
 	   (nAssign gt  25) and (nAssign le 125): newCodes = 1000LL*(idBase+1) + iy[0:nAssign-1]
 	   (nAssign gt 125) and (nAssign le 625): newCodes = 10000LL*(idBase+1) + iz[0:nAssign-1]
 	   else: stop, 'need additional trickery'
 	  endcase
 	  pfafCode_seg[ixAssign] = strtrim(newCodes,2) + '01'
 	  if(max(strlen(pfafCode_seg[ixAssign])) gt 18)then stop, 'very long string'
 	  ;print, 'pfafCoast = ', pfafCode_seg[ixAssign]  
 	 endfor
 	endif
    
 	; get the index/id of the next coastal flowline
 	ixCoast = where(comId_seg[ixCoastline] eq shape_toComID[iyCoast[0]], nMatch)
 	iyCoast = ixCoastline[ixCoast]
 	idCoast = comId_seg[iyCoast[0]]
 	;print, 'iyCoast, idCoast = ', iyCoast[0], idCoast
    
 	nCoast  = nCoast+1
    endwhile
    print, 'nCoast = ', nCoast
 
   endfor  ; looping through coastal regions
 
  endif ; if there are some coastline segments
 
  ; *****
  ; * CHECK ALL FLOWLINES ARE UNIQUE... 
  ; ***********************************
 
  ; skip the check
  ;if(nCoastline eq 0)then goto, skipCheck
  goto, skipCheck
 
  ; get first four characters of pfafstetter code
  cStart = strmid(strtrim(pfafCode_seg,2), 0, 4)
 
  ; loop through Pfafstetter subsets
  for pfaf1=1L,9 do begin
   for pfaf2=0L,9 do begin
    for pfaf3=0L,9 do begin
 	for pfaf4=0L,9 do begin
  
 	 ; get prefix
 	 cPref = strtrim(1000L*pfaf1 + 100L*pfaf2 + 10L*pfaf3 + pfaf4, 2)
   
 	 ; get subset
 	 ixSubset = where(cPref eq cStart, nSubset)
 	 if(nSubset eq 0)then continue
 	 print, 'checking flowline - ', cPref, ': ', nSubset
   
 	 ; get the match
 	 for iSubset=0,nSubset-1 do begin
 	  jSubset = ixSubset[iSubset]
 	  ixMatch = where(pfafCode_seg[ixSubset] eq pfafCode_seg[jSubset], nMatch)
 	  if(nMatch gt 1)then begin
 	   print, 'pfafCode = ', pfafCode_seg[jSubset]
 	   stop, 'duplicate code'
 	  endif
 	 endfor
  
 	endfor  ; pfaf4
    endfor  ; pfaf3
   endfor  ; pfaf2
  endfor  ; pfaf1
 
  skipCheck:
 
  ;stop, 'check great lakes'
 
  ; *****
  ; * ASSIGN COASTAL BASINS IN CATCHMENT FILES...
  ; *********************************************
 
  ; get the desired attributes from the flow lines
  print, 'Reading '+cat_file
  get_attributes, cat_file, 'FEATUREID', comId_cat
  get_attributes, cat_file, 'PFAF_CODE', pfafCode_cat
   
  ; get the number of catchments
  nCat = n_elements(pfafCode_cat)

  ; check if there are coastlines
  if(nCoastline gt 0)then begin
 
   ; identify unassigned catchments
   print, 'Assign coastal basins in catchment files...'
   ixDesire = where(strtrim(pfafCode_cat,2) eq '-9999', nDesire)
   if(nDesire eq 0)then stop, 'no unassigned catchments'
   
   ; loop through unassigned catchments
   for iDesire=0,nDesire-1 do begin
   
    ; get index
    jDesire = ixDesire[iDesire]
   
    ; identify coastal basins
    ixMatch = where(comId_cat[jDesire] eq comId_seg[ixCoastline], nMatch)
    if(nMatch ne 1)then continue
   
    ; assign Pfafstatter code
    pfafCode_cat[jDesire] = pfafCode_seg[ixCoastline[ixMatch[0]]]
    ;print, iDesire, ': ', pfafCode_cat[jDesire]
   
   endfor  ; looping through unassigned catchments
 
  endif  ; if coastlines
 
  ; *****
  ; * ASSIGN ENDORHEIC BASINS AND ISLAND BASINS IN CATCHMENT FILES...
  ; *****************************************************************
 
  ; identify unassigned catchments
  ixDesire = where(strtrim(pfafCode_cat,2) eq '-9999', nDesire)
  if(nDesire gt 0)then begin 
 
   ; identify assigned catchments
   ixAssign = where(strtrim(pfafCode_cat,2) ne '-9999' and strtrim(pfafCode_cat,2) ne '0', nAssign)
   if(nAssign eq 0)then stop, 'no assigned catchments'
  
   ; read catchment shapefile
   get_shapes, cat_file, cat_shapes
  
   ; get mean coordinates
   xMean = dblarr(nCat)
   yMean = dblarr(nCat)
   print, 'Getting mean catchment coordinates...'
   for iCat=0,nCat-1 do begin
    xMean[iCat] = mean((*(cat_shapes[iCat])).xVec)
    yMean[iCat] = mean((*(cat_shapes[iCat])).yVec)
   endfor
  
   ; define x and y offsets
   xOffset = 0.5d  ; degrees
   yOffset = 0.5d  ; degrees
  
   ; get the base Pfafstetter code
   pfafBase = strarr(nDesire)
  
   ; loop through unassigned catchments
   print, 'Assigning base Pfafstetter code...'
   for iDesire=0,nDesire-1 do begin
  
    ; get index
    jDesire = ixDesire[iDesire]
  
    ; get catchments within bounding box
    ixMatch = where(xMean[ixAssign] ge xMean[jDesire]-xOffset and xMean[ixAssign] le xMean[jDesire]+xOffset and $
  				  yMean[ixAssign] ge yMean[jDesire]-yOffset and yMean[ixAssign] le yMean[jDesire]+yOffset, nMatch)
    if(nMatch eq 0)then stop, 'no catchments within offset'
  
    ; get the distance between each assigned catchment in the bounding box
    xDistance = dblarr(nMatch)
    for iMatch=0,nMatch-1 do begin
     jMatch = ixAssign[ixMatch[iMatch]]
     xDistance[iMatch] = map_2points(xMean[jDesire], yMean[jDesire], xMean[jMatch], yMean[jMatch], /meters)/1000.d
    endfor
  
    ; identify the two closest basins
    ixSort = sort(xDistance)
    nClose = min([nMatch,2])
    ixWant = ixAssign[ixMatch[ixSort[0:nClose-1]]]
  
    ; convert Pfaf codes to an array of integers
    maxDig  = 20
    tempArr = replicate(0, maxDig,nClose)
    for iClose=0,nClose-1 do begin
     tempCode = strtrim(pfafCode_cat[ixWant[iClose]], 2)
     tempLen  = strlen(tempCode)
     tempVec  = intarr(tempLen)
     reads, tempCode, tempVec, format='(20(i1))'
     tempArr[0:tempLen-1,iClose] = tempVec
    endfor
    ;print, tempArr
  
    ; identify the most similar digits
    for iDig=0,maxDig-1 do begin
     if(max( abs(tempArr[iDig,*] - tempArr[iDig,0]) ) ne 0)then begin
  	nIdentical = iDig
  	break
     endif
    endfor
  
    ; save the base Pfafstetter code
    pfafBase[iDesire] = strjoin(strtrim(tempVec[0:min([strlen(tempCode),nIdentical])-1],2))
    ;print, iDesire, nMatch, ': ', pfafBase[iDesire] 
  
   endfor   ; loop through unassigned catchments
  
   ; get a vector to add to the base
   ix = replicate(1,5)*10 + indgen(5)*2 + 1
   for i=3,9,2 do ix = [ix, replicate(i,5)*10 + indgen(5)*2 + 1]
   iy = ix+100
   for j=3,9,2 do begin
    ix = replicate(1,5)*10 + indgen(5)*2 + 1
    for i=3,9,2 do ix = [ix, replicate(i,5)*10 + indgen(5)*2 + 1]
    iy = [iy, ix+j*100]
   endfor
   iz = [iy+1000, iy+3000, iy+5000, iy+7000, iy+9000]
   ;print, 'iy = ', iy
  
   ; loop through unassigned catchments
   print, 'Assigning actual Pfafstetter code...'
   for iDesire=0,nDesire-1 do begin
  
    ; get index
    jDesire = ixDesire[iDesire]
    if(strtrim(pfafCode_cat[jDesire],2) ne '-9999')then continue
  
    ; identify matches
    ixMatch = where(pfafBase eq pfafBase[iDesire], nMatch)
    if(nMatch gt 625)then stop, 'too many matches'
  
    ; assign new codes
    for iMatch=0,nMatch-1 do begin
     jMatch = ixDesire[ixMatch[iMatch]]
     case 1 of
  						(nMatch le  25): pfafCode_cat[jMatch] = pfafBase[iDesire] + '0' + strtrim(ix[iMatch], 2)
  	(nMatch gt  25) and (nMatch le 125): pfafCode_cat[jMatch] = pfafBase[iDesire] + '0' + strtrim(iy[iMatch], 2)
  	(nMatch gt 125) and (nMatch le 625): pfafCode_cat[jMatch] = pfafBase[iDesire] + '0' + strtrim(iz[iMatch], 2)
  	else: stop, 'need additional trickery'
     endcase
     if(strlen(strtrim(pfafCode_cat[jMatch],2)) gt 18)then stop, 'number is too large'
     ;print, iDesire, ': ', pfafCode_cat[jMatch]
    endfor
  
   endfor  ; looping through unassigned catchments

  endif  ; if catchments still unassigned
 
  ; identify unassigned catchments
  ixDesire = where(strtrim(pfafCode_cat,2) eq '-9999', nDesire)
  if(nDesire gt 0)then stop, 'still have some unassigned catchments'
 
  ; *****
  ; * ADD NEW COLUMNS TO SHAPEFILES...
  ; **********************************
 
  ; define the file type
  shapeType = ['Flowline_', 'Catchment_']
 
  ; loop through the file types
  for iType=0,n_elements(shapeType)-1 do begin
 
   ; get name of new shapefile
   new_path = '/Volumes/d1/mclark/NHD_Plus/ancillary_data/nhdPlus_SHPs_coast/'
   new_pref = shapeType[iType] + nhdFiles[0,iFile] + '_' + nhdFiles[1,iFile]
   new_file = new_path + new_pref + '.shp'
   print, 'write shapefile ', new_file
   
   ; freshen the files
   spawn, 'rm ' + new_path + new_pref + '.*'
   case shapeType[iType] of
    'Flowline_':  spawn, 'ogr2ogr ' + new_file + ' ' + seg_file + ' 2> log.txt'
    'Catchment_': spawn, 'ogr2ogr ' + new_file + ' ' + cat_file + ' 2> log.txt'
    else: stop, 'unknown shape type'
   endcase
  
   ; get the attribute names
   mydbf=OBJ_NEW('IDLffShape', new_path+new_pref+'.dbf')
   mydbf->GetProperty, ATTRIBUTE_NAMES=attr_names
   OBJ_DESTROY, mydbf
   
   ; define new variables
   if(shapeType[iType] eq 'Flowline_')then begin
    newVars = ['PFAF_CODE'    , 'drainCoast']
    newType = ['character(30)', 'integer'   ]
   endif else begin
    newVars = ['PFAF_CODE'    ]
    newType = ['character(30)']
   endelse
 
   ; loop through variables
   for iVar=n_elements(newVars)-1,0,-1 do begin
   
    ; define the OGR command
    print, new_pref + ' ADD COLUMN ' + newVars[iVar] + ' ' + newType[iVar]
    ogrCommand = 'ogrinfo -q ' + new_file + ' -sql "ALTER TABLE ' + new_pref + ' ADD COLUMN ' + newVars[iVar] + ' ' + newType[iVar] + '"'
   
    ; add the column for the Pfafstetter code (if it does not exist)
    ixMatch = where(strtrim(attr_names,2) eq newVars[iVar], nMatch)
    if(nMatch eq 0)then begin
   
 	; create the column
 	spawn, ogrCommand
   
 	; get the attribute names again
 	mydbf=OBJ_NEW('IDLffShape', new_path+new_pref+'.dbf')
 	mydbf->GetProperty, ATTRIBUTE_NAMES=attr_names
 	OBJ_DESTROY, mydbf
   
    endif
   
    ; get column
    ixMatch = where(strtrim(attr_names,2) eq newVars[iVar], nMatch)
    if(nMatch ne 1)then stop, 'unexpected column header'
    ixColumn = ixMatch[0]
   
    ; write shapes
    print, 'writing ' + newVars[iVar] + ' to shapefiles'
    mynewshape = OBJ_NEW('IDLffShape', new_file, /update)
    case newVars[iVar] of
 	'drainCoast': mynewshape->SetAttributes, lindgen(nSeg), ixColumn, izDangle
 	'PFAF_CODE':  begin
 	 case shapeType[iType] of
 	  'Flowline_':  mynewshape->SetAttributes, lindgen(nSeg), ixColumn, pfafCode_seg 
 	  'Catchment_': mynewshape->SetAttributes, lindgen(nCat), ixColumn, pfafCode_cat
 	  else: stop, 'unknown shape type'
 	 endcase
 	end ; Pfaf code statement
 	else: stop, 'cannot identify case ' + newVars[iVar]
    endcase
    OBJ_DESTROY, mynewshape
   
   endfor  ; looping through variables
 
  endfor  ; looping through shape types
 
  ; *****
  ; * AGGREGATE DATA FOR THE CONUS...
  ; *********************************
 
  ; match the stream segments in the mizuRoute network
  matchName = savePath + 'matchNetworkMizu_' + nameRegion + '.sav'
  if(file_test(matchName) eq 0)then begin
   print, 'Matching the file ' + matchName
   match, segId_mizu, comId_seg, segId_mizu_ix, comId_seg_ix
   save, segId_mizu_ix, comId_seg_ix, filename=matchName
  endif else begin
   restore, matchName
  endelse
 
  ; aggregate vectors
  if(iFile eq 0)then begin
   comid_cat_conus    = comId_cat
   comid_seg_conus    = comId_seg[comId_seg_ix]
   pfafCode_cat_conus = pfafCode_cat
   pfafCode_seg_conus = pfafCode_seg[comId_seg_ix]
  endif else begin
   comid_cat_conus    = [comid_cat_conus, comId_cat]
   comid_seg_conus    = [comid_seg_conus, comId_seg[comId_seg_ix]]
   pfafCode_cat_conus = [pfafCode_cat_conus, pfafCode_cat]
   pfafCode_seg_conus = [pfafCode_seg_conus, pfafCode_seg[comId_seg_ix]]
  endelse
 
  print, '**********'
  print, '**********'
  print, '**********'
 
 endfor  ; looping through shapefiles
 
 ; save the output 
 save, comid_cat_conus, comid_seg_conus, pfafCode_cat_conus, pfafCode_seg_conus, filename=saveName

; restore file
endif else begin
 restore, saveName
endelse

; *****
; * DEFINE NETWORK TOPOLOGY FILE...
; *********************************

; identify dimensions
nHRU = n_elements(comid_cat_conus)
nSeg = n_elements(comid_seg_conus)

; define the NetCDF file
nc_filepath = '/Volumes/d1/mclark/NHD_Plus/ancillary_data/'
nc_filename = nc_filepath + 'conusPfafstetter_coastalCatchments.nc'

; create file
print, 'Creating the NetCDF file for the network topology'
ncid = ncdf_create(nc_filename, /clobber, /netcdf4_format)

 ; create dimension
 hruId = ncdf_dimdef(ncid, 'hru', nHRU)
 segId = ncdf_dimdef(ncid, 'seg', nSeg)

 ; create the id variables
 varid = ncdf_vardef(ncid, 'hruId',        [hruId], /long)
 varid = ncdf_vardef(ncid, 'segId',        [segId], /long)

 ; create the Pfafstetter variables
 varid = ncdf_vardef(ncid, 'pfafCode_cat', [hruId], /string)
 varid = ncdf_vardef(ncid, 'pfafCode_seg', [segId], /string)

; end file definitions
ncdf_control, ncid, /endef
ncdf_close, ncid

; *****
; * WRITE NETWORK TOPOLOGY FILE...
; ********************************

; write the data
print, 'Writing the NetCDF file for the network topology'
ncid = ncdf_open(nc_filename, /write)

 ; write the index variables
 ncdf_varput, ncid, ncdf_varid(ncid, 'hruId'), comid_cat_conus
 ncdf_varput, ncid, ncdf_varid(ncid, 'segId'), comid_seg_conus

 ; write the Pfafstetter codes
 ncdf_varput, ncid, ncdf_varid(ncid, 'pfafCode_cat'), pfafCode_cat_conus
 ncdf_varput, ncid, ncdf_varid(ncid, 'pfafCode_seg'), pfafCode_seg_conus

; close netcdf file
ncdf_close, ncid

stop
end
