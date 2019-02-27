pro add_hdmaHUC

; used to add HDMA Pfafstetter codes and HUC-12 codes to the shapefiles and CONUS NetCDF files

; *****
; * DEFINE SHAPEFILES...
; **********************

; define string
cString='.'
comId  = 0L
pCode  = 0LL
weight = 0.d

; define entity types
typeCatch  = 5 ; entityType=5 is a polygon
typeStream = 3 ; entityType=3 is a polyLine

; get path to NHD-plus
nhd_root = '/Users/mac414/geospatial_data/NHD_Plus/ancillary_data/'

; define path for .sav files
savePath = nhd_root + 'idlSave/'

; Define shapefiles
nhdFiles = [$
            ['GL','04' ], $
            ['PN','17' ], $
            ['SR','09' ], $
            ['CA','18' ], $
            ['NE','01' ], $
            ['MA','02' ], $
            ['SA','03W'], $
            ['SA','03S'], $
            ['SA','03N'], $
            ['MS','05' ], $
            ['MS','06' ], $
            ['MS','07' ], $
            ['MS','08' ], $
            ['MS','10L'], $
            ['MS','10U'], $
            ['MS','11' ], $
            ['TX','12' ], $
            ['RG','13' ], $
            ['CO','14' ], $
            ['CO','15' ], $
            ['GB','16' ]  ]

; define HDMA and HUC-12 prefixes
cPoly = ['HUC12','HDMA']

; loop through HDMA and HUC-12
for iPoly=0,n_elements(cPoly)-1 do begin

 ; loop through shapefiles
 for iFile=0,n_elements(nhdFiles)/2-1 do begin

  ; define NHD string
  nhdString = 'Catchment_' + nhdFiles[0,iFile] + '_' + nhdFiles[1,iFile]
  
  ; define shapefiles
  shpFile_orig = nhd_root + 'nhdPlus_SHPs_final/'      + nhdString + '.shp'
  shpFile_new  = nhd_root + 'nhdPlus_SHPs_HDMA-HUC12/' + nhdString + '.shp'
  print, shpFile_orig
  
  ; copy shapefiles
  if(file_test(shpFile_new) eq 0)then $
  spawn, 'ogr2ogr ' + shpFile_new + ' ' + shpFile_orig + ' 2> log.txt' ; copy initial shapefile to shp_fileNew
  
  ; *****
  ; * READ WEIGHTS FILE DEFINING CORRESPONDENCE BETWEEN NHD+ AND HDMA...
  ; ********************************************************************
  
  ; define mapping file
  mapping_dir  = nhd_root + 'nhdPlus_' + cPoly[iPoly] + '_mapping/'
  mapping_file = mapping_dir + nhdString + '_' + cPoly[iPoly] + '_intersection.tsv'
  nMapping     = file_lines(mapping_file)-1 ; -1 because of the header
  
  ; define vectors
  comId_map  = lonarr(nMapping)
  pCode_map  = lon64arr(nMapping)
  weight_map = dblarr(nMapping)
  
  ; read mapping file
  openr, in_unit, mapping_file, /get_lun
  readf, in_unit, cString ; read header
  for iMapping=0,nMapping-1 do begin
  
   ; read data
   readf, in_unit, cString
   cVector = strSplit(cString, string(9b), /extract)
   isValid = strmatch(strtrim(cVector,2), 'NA')
  
   ; case where data is valid
   if(total(isValid, /integer) eq 0)then begin
    comId_map[iMapping]  = long(cVector[0])
    pCode_map[iMapping]  = long64(cVector[1])
    weight_map[iMapping] = double(cVector[2])
  
   ; case where data is invalid
   endif else begin
    comId_map[iMapping]  = long(cVector[0])
    pCode_map[iMapping]  = 0L 
    weight_map[iMapping] = 0.d
   endelse
  
  endfor  ; looping through the lines in the file
  free_lun, in_unit 
  
  ; *****
  ; * IDENTIFY THE HDMA POLYGON WITH THE LARGEST AREA IN EACH NHD+ PLOYGON...
  ; *************************************************************************
  
  ; identify unique elements
  ixSort = sort(comId_map)
  kComID = comId_map[ixSort]
  ixUniq = [-1, uniq(kComID)]  ; -1 because add one to get the index
  nUniq  = n_elements(ixUniq)-1
  
  ; define sorted elements
  comId_sort = lonarr(nUniq)
  pCode_sort = lon64arr(nUniq)
  
  ; loop through unique elements
  for iUniq=1,nUniq do begin
  
   ; get index of max weight
   i1 = ixUniq[iUniq-1]+1
   i2 = ixUniq[iUniq]
   xx = max(weight_map[ixSort[i1:i2]], iMax)
   ix = ixSort[i1+iMax]
  
   ; save data 
   comId_sort[iUniq-1] = comId_map[ix]
   pCode_sort[iUniq-1] = pCode_map[ix]
  
  endfor  ; looping through unique elements

  ; *****
  ; * WRITE THE HDMA/HUC12 CODES TO THE SHAPEFILES...
  ; *************************************************
  
  ; get the comID from the shapefiles
  get_attributes, shpFile_orig, 'FEATUREID', comId_shape
  
  ; match the comId
  matchName = savePath + cPoly[iPoly]+'_tsv'+nhdString+'_shape.sav'
  if(file_test(matchName) eq 0)then begin
   print, 'Matching the file ', matchName
   match, comId_sort, comId_shape, comId_sort_ix, comId_shape_ix
   save, comId_sort_ix, comId_shape_ix, filename=matchName
  endif else begin
   restore, matchName
  endelse

  ; check
  print, 'nShape = ', n_elements(comId_shape), n_elements(comId_shape_ix), nUniq
  if(n_elements(comId_shape_ix) ne nUniq)then stop, 'unexpected number of elements'

  ; write codes
  defineAttributes, shpFile_new, cPoly[iPoly], 'character(30)', ixCode ; ixCode = column in the file
  writeAttributes, shpFile_new, ixCode, comId_shape_ix, strtrim(pCode_sort[comId_sort_ix],2)

 endfor  ; looping through shapefiles
endfor  ; loop through polygons

stop
end
