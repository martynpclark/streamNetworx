pro crawlUpstream, iSeg, iTarget, iPfaf, upSeg_count, upsReach, totalArea_mizu, ixAssign, $  ; input
                   ixSubset, ixMainstem, aTributary=aTributary                               ; output

; used to crawl upstream

; inputs:
; iSeg           : starting index
; iTarget        : target index (stopping point)
; iPfaf          : Pfafstetter code
; upSeg_count[*] : number of reaches upstream of a given reach
; upsReach       : data structure containing reaches
; totalArea      : total area above each reach
;
; output
; ixSubset       : indices of the main stem
; ixMainstem     : bytarr defining the main stem
; aTributary     : biggest tributary in each reach

; initialize counter
nSubset = 0L
nVector = n_elements(ixSubset)
;print, 'start: iSeg, area[iSeg] = ', iSeg, totalArea_mizu[iSeg]

; define a very small number
verySmall = 0.0001d ; area (m2)

; crawl upstream
while (upSeg_count[iSeg] gt 0) do begin

 ; increment counter
 nSubset = nSubset + 1
 ;print, 'nSubset = ', nSubset

 ; increase the size of the subset, if needed
 nDesire = nSubset+upSeg_count[iSeg]
 if(nVector le nDesire)then begin
  ixSubset = [ixSubset,replicate(0L,nDesire)]
  if keyword_set(aTributary) then aTributary = [aTributary,replicate(-9999.d,nDesire)]
  nVector = n_elements(ixSubset)
 endif

 ; save the indices of the subset
 ixSubset[nSubset-1] = iSeg
 ;print, 'iSeg, iTarget, area[iSeg] = ', iSeg, iTarget, totalArea_mizu[iSeg]

 ; identify the mainstem
 ixMainstem[iSeg] = iPfaf

 ; get the upstream indices
 ixUps = (*(upsReach[iSeg])).upSegIndices
 ;print, 'upstream indices = ', (*(upsReach[iSeg])).upSegIndices
 ;print, 'upSeg_count = ', upSeg_count[iSeg]
 
 ; get the upstream area
 uArea = totalArea_mizu[ixUps]

 ; modify the upstream area if there are zero-area tributaries
 ixZero = where(uArea lt verySmall, nZero, complement=nonZero, ncomplement=nValid)
 if(nZero gt 0)then begin
  totalArea_mizu[ixUps[ixZero]] = totalArea_mizu[ixUps[ixZero]] + verySmall
  if(nValid gt 0)then totalArea_mizu[ixUps[nonZero]] = totalArea_mizu[ixUps[nonZero]] - verySmall/double(nValid)
 endif

 ; save tributaries
 if keyword_set(aTributary)then begin
  if(upSeg_count[iSeg] gt 1)then begin

   ; get 2nd largest trib
   ixSort  = sort(uArea)
   ixReach = ixSort[upSeg_count[iSeg]-2]   ; 2nd largest area
   if(ixAssign[ixUps[ixReach]] eq 0)then aTributary[nSubset-1] = uArea[ixReach]

   ; special case of >2 tributaries
   if(upSeg_count[iSeg] gt 2)then begin
    for ixMult=upSeg_count[iSeg]-3,0,-1 do begin
     ixReach = ixSort[ixMult]
     if(ixAssign[ixUps[ixReach]] eq 0)then begin
      nSubset = nSubset+1
      aTributary[nSubset-1] = uArea[ixReach]   
      ixSubset[nSubset-1]   = iSeg
     endif
    endfor
   endif  ; if >2 tributaries

   ;if(upSeg_count[iSeg] gt 2)then begin
    ;print, '          nSubset-1 = ', nSubset-1
    ;print, '          iSeg  = ', iSeg
    ;print, '          uArea = ', uArea
    ;print, '          upd ids = ', (*(upsReach[iSeg])).upSegIds
    ;print, '          upd ixs = ', (*(upsReach[iSeg])).upSegIndices
    ;print, '          ixAssign = ', ixAssign[ixUps] 
    ;print, '          aTributary[nSubset-1] = ', aTributary[nSubset-1]
   ;endif

  endif
 endif

 ; get the next index on the main stem
 xArea = max(uArea, iPos)
 jSeg = ixUps[iPos]

 ; check if done
 if(iSeg eq iTarget and jSeg ne iSeg)then break
 iSeg = jSeg

endwhile  ; crawling upstream

;print, 'iSeg = ', iSeg

; save the last subset
if(nSubset eq 0 or ixSubset[nSubset-1] ne iSeg)then begin
 nSubset = nSubset+1
 ixSubset[nSubset-1] = iSeg
 ixMainstem[iSeg]    = iPfaf
endif

; restrict attention to desired subsets
ixSubset   = ixSubset[0:nSubset-1]
if keyword_set(aTributary) then begin
 ;print, 'nSubset = ', nSubset
 aTributary = aTributary[0:nSubset-1]
 ;print, 'aTributary = ', aTributary[0:nSubset-1]
endif

end
