pro coastalTrib, oldPfaf, upsArea, ixSubset, newPfaf

; oldPfaf  = old Pfafstetter code
; upsArea  = upstream area
; ixSubset = indices defining subset for a given level
; newPfaf  = new Pfafstetter code

; get the upstream area of each coastal segment
upstreamArea = upsArea[ixSubset]

; get the tributaries
ixTrib = where(upstreamArea gt 0.d, nTrib)
nTrib  = min([nTrib, 4]) ; try to have 4 tributaries
if(nTrib eq 0)then return

; initialize the Pfaffstetter code
newPfaf[ixSubset] = 1

; sort the areas
ixSort = reverse(sort(upstreamArea))
ixJunc = ixSort[0:nTrib-1]
iyJunc = ixJunc[sort(ixJunc)]

; initialze the first junction
izJuncOld = 0

; loop through the tributaries
for iTrib=nTrib-1,0,-1 do begin

 ; define basin indices
 tribBasin  = (iTrib+1)*2
 interBasin = (iTrib+1)*2 + 1

 ; define the junction index
 izJunc = iyJunc[nTrib-1-iTrib]

 ; define the Pfaffstetter code
 newPfaf[ixSubset[izJunc]] = tribBasin
 if(izJunc gt 0 and izJuncOld le izJunc-1)then newPfaf[ixSubset[izJuncOld:izJunc-1]] = interBasin
 izJuncOld = izJunc+1

endfor  ; looping through tributaries

end
