pro get_shapes, shp_filename, shapes

; return to the main program
on_error, 2

; Open the Shapefile
myshape=OBJ_NEW('IDLffShape', shp_filename)

 ; Get the number of entities so we can parse through them
 myshape->IDLffShape::GetProperty, N_ENTITIES=num_ent

 ; define shapes
 shapes=ptrarr(num_ent, /allocate_heap)

 ; Parsing through the entities
 FOR ix=0L, (num_ent-1) DO BEGIN
  ; Print progress
  if(ix mod 10000L eq 0L)then print, 'Processing '+strtrim(shp_filename,2)+': ', ix, num_ent
  ; Get entity
  ent=myshape->IDLffShape::GetEntity(ix)
  ; get the parts of the entity
  nParts = ent[0].n_parts
  iStart = *ent[0].parts
  iCount = replicate(0, nParts)
  iCount[nParts-1] = ent[0].n_vertices - iStart[nParts-1]
  if(nParts gt 1)then iCount[0:nParts-2] = istart[1:nParts-1] - istart[0:nParts-2]
  ; Save basins
  *(shapes[ix])={xVec:reform((*ent.vertices)[0,*]), $ ; x Vector
	             yVec:reform((*ent.vertices)[1,*]), $ ; y vector
	             iStart:iStart                    , $ ; start index of parts
	             iCount:iCount                    , $ ; number of vertices in a part
	             nParts:nParts                    }   ; number of parts in the polygon
  ; Clean-up of pointers
  myshape->IDLffShape::DestroyEntity, ent
 ENDFOR  ; parsing through the entities

; Close the Shapefile
OBJ_DESTROY, myshape

end
