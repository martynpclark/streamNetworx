pro identifyDangle

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
            ['PN','17' ], $
            ['SA','03N'], $
            ['MS','10U'], $
            ['CO','14' ], $
            ['GB','16' ], $
            ['SR','09' ], $
            ['CA','18' ], $
            ['NE','01' ], $
            ['MA','02' ], $
            ['SA','03W'], $
            ['SA','03S'], $
            ['GL','04' ], $
            ['MS','05' ], $
            ['MS','06' ], $
            ['MS','07' ], $
            ['MS','08' ], $
            ['MS','10L'], $
            ['MS','11' ], $
            ['TX','12' ], $
            ['RG','13' ], $
            ['CO','15' ], $
            ['MA','02' ]  ]

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

; close file
ncdf_close, nc_file

; loop through shapefiles
for iFile=0,n_elements(nhdFiles)/2-1 do begin

 ; *****
 ; * GET STREAM SEGMENTS...
 ; ************************

 ; define shapefiles
 nhdString = 'Flowline_' + nhdFiles[0,iFile] + '_' + nhdFiles[1,iFile]
 shpFile_orig = nhd_root + 'nhdPlus_SHPs_final/' + nhdString + '.shp'
 print, shpFile_orig

 ; get the shapes
 get_attributes, shpFile_orig, 'COMID', comId_sh
 get_shapes,     shpFile_orig, flowline_shapes

 ; get the number of shapes
 nShapes = n_elements(comId_sh)

 ; *****
 ; * GET SUBSET OF DANGLING REACHES IN A SPECIFIC REGION...
 ; ********************************************************
 
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
 ; * DEFINE DANGLING REACHES...
 ; ****************************

 ; define "dangling" reaches
 ixDangle = where(downSegId[segId_mizu_ix] le 0, nDangle)
 print, 'Processing ', nameRegion, '; nDangle = ', nDangle

 ; loop through dangling reaches
 for iDangle=0,nDangle-1 do begin

  ; get indices to the shape file and the national database
  jDangle = ixDangle[iDangle]
  iShape  = comID_sh_ix[jDangle]
  iMizu   = segId_mizu_ix[jDangle]

  ; check
  if(comID_sh[iShape] ne segId_mizu[iMizu])then stop, 'mismatch in comID'
  if(downSegId[iMizu] gt 0)then stop, 'expect downSegId to be less than or equal to zero'

  ; write shapefile
  writeShapefile, typeLine, iShape, jShape, segId_mizu[iMizu], shapeFile_dangle, flowline_shapes 

  ; define attributes
  if(jShape eq 0)then begin 
   defineAttributes, shapeFile_dangle, 'idUnique',  'integer', ixUnique       ; ixUnique  = column in the file
   defineAttributes, shapeFile_dangle, 'upsArea',   'float',   ixUpsArea      ; ixUpsArea = column in the file
  endif

  ; write attributes 
  writeAttributes,  shapeFile_dangle, ixUnique,  jShape, comID_sh[iShape]
  writeAttributes,  shapeFile_dangle, ixUpsArea, jShape, totalArea_mizu[iMizu]

  ; increment shapefile index
  jShape=jShape+1

 endfor  ; looping through dangling reaches

endfor  ; looping through regions


stop
end
