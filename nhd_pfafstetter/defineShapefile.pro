pro defineShapefile, entityType, layerNames, shp_file

; entityType=3 is a polyLine
; entityType=5 is a polygon

; create shapefile
mynewshape = OBJ_NEW('IDLffShape', shp_file, /update, entity_type=entityType)

; define attributes
mynewshape->GetProperty, N_ATTRIBUTES=nAttributes
for iAtt=0,n_elements(layerNames)-1 do begin
 mynewshape->AddAttribute, layerNames[iAtt], 3, 10
endfor

; close the shapefile
mynewshape->Close
OBJ_DESTROY, mynewshape

; add projection info
spawn, 'ogr2ogr -a_srs EPSG:4326 ' + shp_file + ' ' + shp_file

end
