pro addShape_pfafstetter, file_desire

; check command line arguments
if(n_elements(file_desire) eq 0)then stop, 'need to provide the NetCDF file name'

; define parameters
no=0
yes=1

; define path for .sav files
savePath = '/Volumes/d1/mclark/NHD_Plus/ancillary_data/idlSave/'

; *****
; * READ THE PFAFSTETTER CODES...
; *******************************

nc_filepath = '/Volumes/d1/mclark/NHD_Plus/ancillary_data/'
nc_filename = nc_filepath + file_desire 
print, 'Reading the Pfafstetter code'

; open file
ncid = ncdf_open(nc_filename, /nowrite)

; read the index variables
ncdf_varget, ncid, ncdf_varid(ncid, 'hruId'), hruId_mizu
ncdf_varget, ncid, ncdf_varid(ncid, 'segId'), segId_mizu

; read the pfafstetter codes
ncdf_varget, ncid, ncdf_varid(ncid, 'pfafCode_cat'), pfafCode_cat
ncdf_varget, ncid, ncdf_varid(ncid, 'pfafCode_seg'), pfafCode_seg

; read the pfafstetter class
varid_cat = ncdf_varid(ncid, 'pfafClass_cat')
varid_seg = ncdf_varid(ncid, 'pfafClass_seg')
if(varid_cat eq -1 or varid_seg eq -1)then begin
 isClass=no
endif else begin
 isClass=yes
 ncdf_varget, ncid, varid_cat, pfafClass_cat
 ncdf_varget, ncid, varid_seg, pfafClass_seg
endelse

; close file
ncdf_close, ncid

; *****
; * DEFINE SHAPEFILES...
; **********************

; get path to shapefile
shp_path = '/Volumes/d1/mclark/NHD_Plus/ancillary_data/nhdPlus_SHPs_final/'

; Define shapefiles
nhdFiles = [$
            ['SA','03N'], $
            ['PN','17' ], $
            ['MS','05' ], $
            ['CO','14' ], $
            ['MS','10U'], $
            ['CO','15' ], $
            ['GB','16' ], $
            ['SR','09' ], $
            ['CA','18' ], $
            ['NE','01' ], $
            ['SA','03W'], $
            ['SA','03S'], $
            ['GL','04' ], $
            ['MS','06' ], $
            ['MS','07' ], $
            ['MS','08' ], $
            ['MS','10L'], $
            ['MS','11' ], $
            ['TX','12' ], $
            ['RG','13' ], $
            ['MA','02' ]  ]

; Define shapefile type
shapeType = ['Catchment_', 'Flowline_']

; loop through shapefiles
for iFile=0,n_elements(nhdFiles)/2-1 do begin

 ; loop through shapefile types
 for iType=0,n_elements(shapeType)-1 do begin

  ; *****
  ; * READ SHAPEFILES...
  ; ********************
  
  ; define the shapefile
  shp_file = shp_path + shapeType[iType] + nhdFiles[0,iFile] + '_' + nhdFiles[1,iFile] + '.shp'
  print, shp_file
  
  ; get the COMID
  if(shapeType[iType] eq 'Catchment_')then get_attributes, shp_file, 'FEATUREID', comId_sh
  if(shapeType[iType] eq 'Flowline_') then get_attributes, shp_file, 'COMID',     comId_sh
  
  ; get the match
  if(isClass eq no)  then matchName = savePath + 'matchShapePfafstetter_' + shapeType[iType] + nhdFiles[0,iFile] + '_' + nhdFiles[1,iFile] + '.sav'
  if(isClass eq yes) then matchName = savePath + 'matchShapeAggregate_' + shapeType[iType] + nhdFiles[0,iFile] + '_' + nhdFiles[1,iFile] + '.sav'
  spawn, 'rm ' + matchName
  if(file_test(matchName) eq 0)then begin
   print, 'Matching the file ', matchName
   ; match
   if(shapeType[iType] eq 'Catchment_')then match, hruId_mizu, comID_sh, hruId_mizu_ix, comID_sh_ix
   if(shapeType[iType] eq 'Flowline_' )then match, segId_mizu, comID_sh, segId_mizu_ix, comID_sh_ix
   ; save
   if(shapeType[iType] eq 'Catchment_')then save, hruId_mizu_ix, comID_sh_ix, filename=matchName 
   if(shapeType[iType] eq 'Flowline_' )then save, segId_mizu_ix, comID_sh_ix, filename=matchName
  endif else begin
   print, 'Restoring the file ', matchName
   restore, matchName
  endelse
  
  ; define the number of stream segments
  nSeg = n_elements(segId_mizu_ix)

  ; *****
  ; * ADD "PFAF_CODE" COLUMN TO SHAPEFILES...
  ; *****************************************

  ; get path of new shapefile
  if(isClass eq no) then new_path = '/Volumes/d1/mclark/NHD_Plus/ancillary_data/nhdPlus_SHPs_pfaf/'
  if(isClass eq yes)then new_path = '/Volumes/d1/mclark/NHD_Plus/ancillary_data/nhdPlus_SHPs_class/'
  
  ; get name of new shapefile
  new_pref = shapeType[iType] + nhdFiles[0,iFile] + '_' + nhdFiles[1,iFile]
  new_file = new_path + new_pref + '.shp'
  print, 'write shapefile ', new_file

  ; freshen the files
  spawn, 'rm ' + new_path + new_pref + '.*'
  spawn, 'ogr2ogr ' + new_file + ' ' + shp_file + ' 2> log.txt'
 
  ; get the attribute names
  mydbf=OBJ_NEW('IDLffShape', new_path+new_pref+'.dbf')
  mydbf->GetProperty, ATTRIBUTE_NAMES=attr_names
  OBJ_DESTROY, mydbf
 
  ; define new variables
  newVars = ['PFAF_CODE',     'PFAF_CLASS',    'MILK_RIVER']
  newType = ['character(30)', 'character(30)', 'integer']
  for iVar=n_elements(newVars)-1,0,-1 do begin

   ; check if the variable is needed
   if(newVars[iVar] eq 'PFAF_CLASS')then begin
    if(isClass eq no)then continue
   endif

   ; check if in the upper Missouri
   if(newVars[iVar] eq 'MILK_RIVER')then begin
    if(nhdFiles[1,iFile] ne '10U')then continue
   endif  

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
   
   endif   ; adding column to shapefiles
  
  endfor  ; looping through variables
   
  ; *****
  ; * WRITE "PFAF_CODE" COLUMN TO SHAPEFILES...
  ; *******************************************
  
  ; match the desired column
  ixMatch = where(strtrim(attr_names,2) eq 'PFAF_CODE', nMatch)
  if(nMatch ne 1)then stop, 'unexpected column header'
  ixColumn = ixMatch[0]
   
  ; initialize the pfaf code
  nShape    = n_elements(comId_sh)
  pfafShape = replicate('-9999', nShape)
  
  ; define the Pfafstetter codes
  if(shapeType[iType] eq 'Catchment_')then pfafShape[comID_sh_ix] = pfafCode_cat[hruId_mizu_ix] 
  if(shapeType[iType] eq 'Flowline_' )then pfafShape[comID_sh_ix] = pfafCode_seg[segId_mizu_ix]

  ; write shapes
  print, 'writing PFAF_CODE to shapefiles'
  mynewshape = OBJ_NEW('IDLffShape', new_file, /update)
  mynewshape->SetAttributes, lindgen(nShape), ixColumn, pfafShape
  OBJ_DESTROY, mynewshape 

  ; *****
  ; * WRITE "PFAF_CLASS" COLUMN TO SHAPEFILES...
  ; *******************************************

  if(isClass eq yes)then begin

   ; match the desired column
   ixMatch = where(strtrim(attr_names,2) eq 'PFAF_CLASS', nMatch)
   if(nMatch ne 1)then stop, 'unexpected column header'
   ixColumn = ixMatch[0]
  
   ; initialize the pfaf code
   nShape    = n_elements(comId_sh)
   pfafShape = replicate('-9999', nShape)
  
   ; define the Pfafstetter codes
   if(shapeType[iType] eq 'Catchment_')then pfafShape[comID_sh_ix] = pfafClass_cat[hruId_mizu_ix] 
   if(shapeType[iType] eq 'Flowline_' )then pfafShape[comID_sh_ix] = pfafClass_seg[segId_mizu_ix]
  
   ; write shapes
   print, 'writing PFAF_CLASS to shapefiles'
   mynewshape = OBJ_NEW('IDLffShape', new_file, /update)
   mynewshape->SetAttributes, lindgen(nShape), ixColumn, pfafShape
   OBJ_DESTROY, mynewshape

  endif

  ; *****
  ; * WRITE "MILK_RIVER" COLUMN TO SHAPEFILES...
  ; ********************************************

  ; check if in the upper Missouri
  if(nhdFiles[1,iFile] eq '10U')then begin
  
   ; match the desired column
   ixMatch = where(strtrim(attr_names,2) eq 'MILK_RIVER', nMatch)
   if(nMatch ne 1)then stop, 'unexpected column header'
   ixColumn = ixMatch[0]
   
   ; initialize the pfaf code
   nShape   = n_elements(comId_sh)
   subShape = replicate(0L, nShape)
   
   ; define the subset
   ixSubset = where(strmid(strtrim(pfafShape,2),0,3) eq '898', nSubset)
   if(nSubset gt 0)then subShape[ixSubset] = 1L
   
   ; write shapes
   mynewshape = OBJ_NEW('IDLffShape', new_file, /update)
   mynewshape->SetAttributes, lindgen(nShape), ixColumn, subShape
   OBJ_DESTROY, mynewshape

  endif  ; if in the upper Missouri
 
 endfor  ; looping through file types

 ;stop, 'completed shapefile'

endfor  ; looping through shape files


stop
end
