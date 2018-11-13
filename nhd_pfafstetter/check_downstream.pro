pro check_downstream, iyMax, downSegIndex_mizu, iyMainstem, isDownstream

; check if the reaches drain through the bottom basin

; define check array
nMainstem    = n_elements(iyMainstem)
isDownstream = replicate(0, nMainstem)

; loop through reaches on the main stem
for iStem=0,nMainstem-1 do begin

 ; the most downstream basin
 if(iyMainstem[iStem] eq iyMax)then begin
  isDownstream[iStem] = 1

 ; all other basins
 endif else begin
  jStem = downSegIndex_mizu[iyMainstem[iStem]]-1
  while (jStem ge 0) do begin
   if(jStem eq iyMax)then isDownstream[iStem] = 1
   jStem = downSegIndex_mizu[jStem]-1
  endwhile
 endelse

endfor  ; looping through basins

end
