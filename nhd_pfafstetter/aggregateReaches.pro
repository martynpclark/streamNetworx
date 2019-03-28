pro aggregateReaches, ixSubset, pCode, downSegId_mizu, endLat, endLon, pfafId

; used to aggregate reaches

; constants
areaConv = 1.d+3  ; m-->km
areaMax  = 25.d   ; 25 km

; check if there are multiple dangling reaches
ixDangle = where(downSegId_mizu[ixSubset] le 0, nDangle)
if(nDangle gt 1)then begin
 
 ; get the distance among dangling reaches
 iyDangle  = ixSubset[ixDangle]
 xDistance = replicate(0.d, nDangle,nDangle)
 for iDangle=1,nDangle-1 do begin
  for jDangle=0,iDangle-1 do begin
   xDistance[iDangle,jDangle] = map_2points(endLon[iyDangle[iDangle]], endLat[iyDangle[iDangle]], endLon[iyDangle[jDangle]], endLat[iyDangle[jDangle]], /meters)
  endfor
 endfor

 ; only aggregate if the maximum distance is small
 if(max(xDistance)/areaConv lt areaMax)then pfafId[ixSubset] = pCode

; standard case = no more than one dangling reach
endif else begin
 pfafId[ixSubset] = pCode  ; simple aggregation
endelse

end
