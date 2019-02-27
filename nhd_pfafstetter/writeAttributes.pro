pro writeAttributes, shp_file, ixColumn, ixIndex, attr_value

; return to the calling program
on_error, 2

; write shapes
mynewshape = OBJ_NEW('IDLffShape', shp_file, /update)
mynewshape->SetAttributes, ixIndex, ixColumn, attr_value
OBJ_DESTROY, mynewshape

end
