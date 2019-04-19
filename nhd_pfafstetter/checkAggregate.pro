pro checkAggregate, pCode, areaMax, pfafVec_string, basArea_mizu, totalArea, ixSubset, aggregate

; named variables
no      = 0
yes     = 1
missing = -9999

; define original code
original=yes

; *****
; * ORIGINAL CODE...
; ******************

; original code
if(original eq yes)then begin
 if(totalArea lt areaMax)then aggregate=yes else aggregate=no

; *****
; * NEW CODE...
; *************

; new code
endif else begin

 ; get the vector of areas for the next level
 agAreaVec = replicate(0.d, 10)
 
 ; loop through the next level
 for jPfaf=0,9 do begin
 
  ; update the Pfafstetter code
  pCodeTemp = pCode + strtrim(jPfaf,2)
 
  ; get the subset for a section in the next level
  jxSubset  = where(strmid(pfafVec_string[ixSubset], 0, strlen(pCodeTemp)) eq pCodeTemp, nSubset)
  if(nSubset gt 0)then agAreaVec[jPfaf] = total(basArea_mizu[ixSubset[jxSubset]])
 
 endfor ; looping through the next level
 
 ; check
 ;print, 'areas in the next level = ', agAreaVec
 if(abs(total(agAreaVec) - totalArea) gt 0.1d)then stop, 'area mismatch'
 
 ; get the minimum area
 agAreaMin = min(agAreaVec[where(agAreaVec gt 0.1d)], iMin)
 
 ; initialize aggregate
 aggregate=missing
 
 ; don't aggregate if minimum of all sub-basins is greater than the threshold
 if(agAreaMin gt areaMax)then begin
  aggregate=no
 
 ; minumum area is less than the threshold
 endif else begin
 
  ; maximum area is less than the threshold
  if(totalArea lt areaMax)then aggregate=yes
 
  ; the maximum area is greater than the threshold but there is a really small sub-basin
  if(abs(agAreaMin - areaMax) gt abs(totalArea - areaMax))then aggregate=yes else aggregate=no
 
 endelse
 
 ; check
 if(aggregate eq missing)then stop, 'expect aggretate to be assigned'

endelse 

end
