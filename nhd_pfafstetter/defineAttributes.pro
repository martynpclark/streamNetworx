pro defineAttributes, shp_file, attr_newName, attr_newType, ixColumn

; get the attribute names
myshp=OBJ_NEW('IDLffShape', shp_file)
myshp->GetProperty, ATTRIBUTE_NAMES=attr_names
OBJ_DESTROY, myshp

; check if the attribute exists
ixMatch = where(strtrim(attr_names,2) eq attr_newName, nMatch)
if(nMatch eq 0)then begin

 ; add the column for the new attribute
 layerName  = file_basename(shp_file, '.shp')
 ogrCommand = 'ogrinfo -q ' + shp_file + ' -sql "ALTER TABLE ' + layerName + ' ADD COLUMN ' + attr_newName + ' ' + attr_newType + '"'
 spawn, ogrCommand

 ; get the attribute names again
 myshp=OBJ_NEW('IDLffShape', shp_file)
 myshp->GetProperty, ATTRIBUTE_NAMES=attr_names
 OBJ_DESTROY, myshp 

endif  ; if attribute does not exist

; identify the desired column
ixMatch = where(strtrim(attr_names,2) eq attr_newName, nMatch)
if(nMatch ne 1)then stop, 'unexpected column header'
ixColumn = ixMatch[0]

end
