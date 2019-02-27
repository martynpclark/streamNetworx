pro writeShapefile, entityType, oldIndex, newIndex, idUnique, shp_file, shapes

; return on error
on_error, 2

; entityType=3 is a polyLine
; entityType=5 is a polygon

; create shapefile
if(newIndex eq 0)then begin
 mynewshape = OBJ_NEW('IDLffShape', shp_file, /update, entity_type=entityType)
endif else begin
 mynewshape = OBJ_NEW('IDLffShape', shp_file, /update)
endelse
entNew = {IDL_SHAPE_ENTITY}

; define entity type
entNew.shape_type = entityType

; define attributes
mynewshape->GetProperty, N_ATTRIBUTES=nAttributes
if(nAttributes eq 0)then mynewshape->AddAttribute, 'idUnique', 3, 10
attrNew = mynewshape->GetAttributes(/ATTRIBUTE_STRUCTURE)

; define polygon index
iPoly = oldIndex  ; index in original shape file

; loop through the polygon parts
for iPart=0,(*(shapes[iPoly])).nParts-1 do begin

 ; get start and count indices
 iStart = (*(shapes[iPoly])).iStart[iPart]
 iCount = (*(shapes[iPoly])).iCount[iPart]

 ; get x+y polygon vectors
 if(iPart eq 0)then begin
  xVec = (*(shapes[iPoly])).xVec[iStart:iStart+iCount-1]
  yVec = (*(shapes[iPoly])).yVec[iStart:iStart+iCount-1]
 endif else begin
  xVec = [xVec, (*(shapes[iPoly])).xVec[iStart:iStart+iCount-1]]
  yVec = [yVec, (*(shapes[iPoly])).yVec[iStart:iStart+iCount-1]]
 endelse

endfor  ; looping through entity parts

; define bounds
entNew.bounds[0] = min(xVec)
entNew.bounds[1] = min(yVec)
entNew.bounds[4] = max(xVec)
entNew.bounds[5] = max(yVec)

; define vertices
entNew.n_vertices = n_elements(xVec)
entNew.vertices   = ptr_new(transpose([ [xVec] , [yVec] ]), /No_Copy)

; define parts
parts = (*(shapes[iPoly])).iStart
entNew.n_parts = n_elements(parts)
entNew.parts   = ptr_new(parts, /No_Copy)

; set attribute
attrNew.ATTRIBUTE_0 = idUnique

; add the new entity to new shapefile.
mynewshape->PutEntity, entNew

; add the attribute to the shapefile
mynewshape->SetAttributes, newIndex, attrNew

; close the shapefile
mynewshape->Close
OBJ_DESTROY, mynewshape

; add projection info
; NOTE -- workaround because problems overwriting
if(newIndex eq 0)then begin
 spawn, 'ogr2ogr -a_srs EPSG:4326 shpfile-temp.shp ' + shp_file
 spawn, 'ogr2ogr ' + shp_file + ' shpfile-temp.shp'  ; copy temporary shapefile to shp_file
endif
 
end
