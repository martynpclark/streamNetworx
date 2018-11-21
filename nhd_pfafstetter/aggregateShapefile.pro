pro aggregateShapefile, entityType, ixIndex, layerNames, intVec, shp_file, shapes, indexShapes

; entityType=3 is a polyLine
; entityType=5 is a polygon

; define maximum attributes

; create shapefile
mynewshape = OBJ_NEW('IDLffShape', shp_file, /update)
entNew = {IDL_SHAPE_ENTITY}

; define entity type
entNew.shape_type = entityType

; get the number of attributes
mynewshape->GetProperty, N_ATTRIBUTES=nAttributes
mynewshape->GetProperty, ATTRIBUTE_NAMES=attr_names
if(n_elements(layerNames) ne nAttributes)then stop, 'unexpected attributes exist in file ' + shp_file

; get attributes
attrNew = mynewshape->GetAttributes(/ATTRIBUTE_STRUCTURE)

; set attributes 
for iAtt=0,nAttributes-1 do begin
 ixMatch = where(strmatch(strtrim(attr_names,2), strtrim(layerNames[iAtt],2)) eq 1, nMatch)
 if(nMatch ne 1)then stop, 'expect a unique match'
 attrNew.(ixMatch[0]) = intVec[ixMatch[0]]
endfor

; add the attribute to the shapefile
mynewshape->SetAttributes, ixIndex, attrNew

; =====================================================================================
; =====================================================================================
; =====================================================================================

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

; add the new entity to new shapefile.
mynewshape->PutEntity, entNew

; =====================================================================================
; =====================================================================================
; =====================================================================================

; close the shapefile
mynewshape->Close
OBJ_DESTROY, mynewshape

end
