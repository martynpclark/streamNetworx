pro get_downstream, iyMainstem, totalArea_mizu, pClass_seg, downSegIndex_mizu, iyMax, iyDown

; get the index of the downstream reach id
xMax   = max(totalArea_mizu[iyMainstem], iMax)
iyMax  = iyMainstem[iMax]      ; lowest reach on the main stem = the reach with the largest area

; need to loop to account for zero-length connector segments
for iStem=1,9 do begin

 ; not an outlet
 if(downSegIndex_mizu[iyMax] gt 0)then begin

  ; check if iyMax is the most downstream basin
  iyDown = downSegIndex_mizu[iyMax] -1  ; -1 to convert from 1-based indexing to 0-based indexing
  if(pClass_seg[iyDown] ne pClass_seg[iyMax])then break

  ; update iyMax
  iyMax = downSegIndex_mizu[iyMax]-1

 ; outlet
 endif else begin
  iyDown = -1L
  break
 endelse

 ; check
 if(iStem eq 9)then stop, 'unable to identify downstream segment'

endfor  ; loop to account for zero-length connector segments

end
