pro locationDangle, segId_mizu, downSegId_mizu, endLat, endLon

; Used to find the end point of each reach
 
; *****
; * DEFINE SHAPEFILES...
; **********************

; get path to NHD-plus
nhd_root = '/Users/mac414/geospatial_data/NHD_Plus/ancillary_data/'

; define path for .sav files
savePath = nhd_root + 'idlSave/'

; get path to shapefile
shp_path = nhd_root + 'nhdPlus_SHPs_final/'

; Define shapefiles
nhdFiles = [$
            ['MS','10U'], $
            ['GB','16' ], $
            ['SR','09' ], $
            ['CA','18' ], $
            ['CO','14' ], $
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
            ['MS','10L'], $
            ['MS','11' ], $
            ['TX','12' ], $
            ['RG','13' ], $
            ['CO','15' ], $
            ['PN','17' ], $
            ['MA','02' ]  ]

; loop through shapefiles
for iFile=0,n_elements(nhdFiles)/2-1 do begin

 ; *****
 ; * GET STREAM SEGMENTS...
 ; ************************

 ; define the shapefile
 shp_file = shp_path + 'Flowline_' + nhdFiles[0,iFile] + '_' + nhdFiles[1,iFile] + '.shp'

 ; get the COMID
 get_attributes, shp_file, 'COMID', comId_sh
 
 ; get the shape file
 get_shapes, shp_file, seg_shapes
 
 ; get the match
 matchName = savePath + 'matchShapeLocation_' + nhdFiles[0,iFile] + '_' + nhdFiles[1,iFile] + '.shp'
 print, matchName
 if(file_test(matchName) eq 0)then begin
  print, 'Matching the file ', matchName
  match, segId_mizu, comID_sh, segId_mizu_ix, comID_sh_ix
  save, segId_mizu_ix, comID_sh_ix, filename=matchName
 endif else begin
  restore, matchName
 endelse
 
 ; define the number of stream segments
 nSeg = n_elements(segId_mizu_ix)
 
 ; *****
 ; * GET LOCATION...
 ; *****************

 ; loop through the subset
 for iSeg=0,nSeg-1 do begin
 
  ; get indices
  ncSeg  = segId_mizu_ix[iSeg]
  iShape = comID_sh_ix[iSeg]
 
  ; get the x and y vectors
  x = (*(seg_shapes[iShape])).xVec
  y = (*(seg_shapes[iShape])).yVec
  n = n_elements(x)

  ; save lat/lon
  endLat[ncSeg] = y[n-1]
  endLon[ncSeg] = x[n-1]

 endfor  ; loping through the subset in the shapefile

endfor  ; looping through shapefiles

end
