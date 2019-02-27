pro get_attributes, dbf_filename, attribute_name, attribute_desire

; return to the main program
on_error, 2

; Set the DBF object
mydbf=OBJ_NEW('IDLffShape')

; Open the .dbf file
ierr = mydbf->IDLffShape::Open(dbf_filename, /DBF_ONLY)
if(ierr ne 1)then message='unable to open the dbf file'

 ; Get all attributes
 attr = mydbf->IDLffShape::GetAttributes(/all)

 ; Get the attribute info
 mydbf->GetProperty, ATTRIBUTE_INFO=attr_info
 mydbf->GetProperty, ATTRIBUTE_NAMES=attr_names

 ; identify the desired attribute
 iMatch = where(strmatch(strupcase(attr_names), strtrim(strupcase(attribute_name),2)), nMatch)

 ; get the desired attribute
 if(nMatch eq 1)then begin
  attribute_desire = reform(attr[*].(iMatch))
 endif else begin
  print, 'Attributes available: ', attr_names
  message, 'Variable '+strtrim(attribute_name,2)+' does not exist in shapefile'
 endelse

; Close the Shapefile
OBJ_DESTROY, mydbf

end
