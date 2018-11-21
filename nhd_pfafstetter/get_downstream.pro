pro get_downstream, iyMainstem, totalArea_mizu, pClass_seg, downSegIndex_mizu, iyMax, iyDown

; return to main program
on_error, 2

; get the index of the downstream reach id
xMax   = max(totalArea_mizu[iyMainstem], iMax)
iyMax  = iyMainstem[iMax]      ; lowest reach on the main stem = the reach with the largest area
;print, 'xMax, iyMax = ', xMax, iyMax

; need to loop to account for zero-length connector segments
for iStem=1,100 do begin

 ; not an outlet
 if(downSegIndex_mizu[iyMax] gt 0)then begin

  ; check if iyMax is the most downstream basin
  iyDown = downSegIndex_mizu[iyMax] -1  ; -1 to convert from 1-based indexing to 0-based indexing
  if(iyDown eq iyMax)then stop, 'expect the downstream index to differ from the max index'
  ;print, iStem, iyDown, iyMax, ': ', pClass_seg[iyDown], ': ', pClass_seg[iyMax], totalArea_mizu[iyMax], totalArea_mizu[iyDown]
  if(pClass_seg[iyDown] ne pClass_seg[iyMax])then break

  ; update iyMax
  iyMax = downSegIndex_mizu[iyMax]-1

 ; outlet
 endif else begin
  iyDown = -1L
  break
 endelse

 ; check
 if(iStem ge 10)then stop, 'get_downstream.pro: unable to identify downstream segment'

endfor  ; loop to account for zero-length connector segments

end
