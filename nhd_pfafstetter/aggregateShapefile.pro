pro aggregateShapefile, entityType, ixIndex, idUnique, shp_file, shapes, indexShapes

; entityType=3 is a polyLine
; entityType=5 is a polygon

; create shapefile
if(ixIndex eq 0)then begin
 mynewshape = OBJ_NEW('IDLffShape', shp_file, /update, entity_type=entityType)
endif else begin
 mynewshape = OBJ_NEW('IDLffShape', shp_file, /update)
endelse
entNew = {IDL_SHAPE_ENTITY}

; define entity type
entNew.shape_type = entityType

; define attributes
mynewshape->GetProperty, N_ATTRIBUTES=nAttributes
if(nAttributes eq 0)then mynewshape->AddAttribute, 'pfafUnique', 3, 10
attrNew = mynewshape->GetAttributes(/ATTRIBUTE_STRUCTURE)

; get the number of elements to aggregate
nSubset = n_elements(indexShapes)

; initialize the shape
firstShape = 0

; loop through subset of shapes
for jPoly=0,nSubset-1 do begin

 ; define polygon index
 iPoly = indexShapes[jPoly]

 ; save indices of ragged array for the polygon parts
 if(firstShape eq 0)then begin
  parts = (*(shapes[iPoly])).iStart
 endif else begin
  parts = [parts, (*(shapes[iPoly])).iStart + n_elements(xVec)]
 endelse

 for iPart=0,(*(shapes[iPoly])).nParts-1 do begin

  ; get start and count indices
  iStart = (*(shapes[iPoly])).iStart[iPart]
  iCount = (*(shapes[iPoly])).iCount[iPart]

  ; get x+y polygon vectors
  if(firstShape eq 0)then begin
   xVec = (*(shapes[iPoly])).xVec[iStart:iStart+iCount-1]
   yVec = (*(shapes[iPoly])).yVec[iStart:iStart+iCount-1]
  endif else begin
   xVec = [xVec, (*(shapes[iPoly])).xVec[iStart:iStart+iCount-1]]
   yVec = [yVec, (*(shapes[iPoly])).yVec[iStart:iStart+iCount-1]]
  endelse

  ; update firstShape
  firstShape=1

 endfor  ; looping through entity parts

endfor  ; looping through subset of shapes

; define bounds
entNew.bounds[0] = min(xVec)
entNew.bounds[1] = min(yVec)
entNew.bounds[4] = max(xVec)
entNew.bounds[5] = max(yVec)

; define vertices
entNew.n_vertices = n_elements(xVec)
entNew.vertices   = ptr_new(transpose([ [xVec] , [yVec] ]), /No_Copy)

; define parts
entNew.n_parts = n_elements(parts)
entNew.parts   = ptr_new(parts, /No_Copy)

; set attribute
attrNew.ATTRIBUTE_0 = idUnique

; add the new entity to new shapefile.
mynewshape->PutEntity, entNew

; add the attribute to the shapefile
mynewshape->SetAttributes, ixIndex, attrNew

; close the shapefile
mynewshape->Close
OBJ_DESTROY, mynewshape

; add projection info
if(ixIndex eq 0)then spawn, 'ogr2ogr -a_srs EPSG:4326 ' + shp_file + ' ' + shp_file
  
end
