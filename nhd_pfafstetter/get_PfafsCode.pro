pro get_pfafsCode, pfafVec, segId_mizu, upSeg_count, upsReach, totalArea_mizu, ixAssign, ixSubset, $  ; input
                   networkSubset, ixMainstem, nTrib, iPrint=iPrint

; return to the main program
;on_error, 2

; define tolerance (area m2)
xTol = 0.01d

; *****
; * IDENTIFY SEGMENTS ON THE MAIN STEM ON THE NETWORK...
; ******************************************************

; define subset vectors
nSubset = n_elements(ixSubset)
mainSubset = lonarr(nSubset)
aTributary = replicate(-9999.d, nSubset)

; define min and max segment
areaMin = min(totalArea_mizu[ixSubset], ixMin)
areaMax = max(totalArea_mizu[ixSubset], ixMax)

; get segMin and segMax
segMin = ixSubset[0]
segMax = ixSubset[n_elements(ixSubset)-1]

; get segMin and segMax
;segMin = ixSubset[ixMax]  ; minimum segment is the maximum area
;segMax = ixSubset[ixMin]  ; maximum segment is the minumum area

; print
if keyword_set(iPrint) then begin
 print, 'area     = ', totalArea_mizu[ixSubset]
 print, 'segMin   = ', segMin
 print, 'segMax   = ', segMax
 print, 'ixSubset = ', ixSubset
endif

; check segMin and segMax
if(abs(totalArea_mizu[segMin] - areaMax) gt xTol)then stop, 'first segment has unexpected area'
if(abs(totalArea_mizu[segMax] - areaMin) gt xTol)then stop, ' last segment has unexpected area'

; label main stem as "9" -- overwrite lower reaches later
iPfCode = 9
segSave = segMin

; crawl upstream to identify tributaries
crawlUpstream, segMin, segMax, ipfCode, upSeg_count, upsReach, totalArea_mizu, ixAssign, $  ; input
               mainSubset, ixMainstem, aTributary=aTributary                                ; output

; print
if keyword_set(iPrint) then print, 'ixMainstem = ', ixMainstem[mainSubset]

; get the number of valid tributaries
ixTrib = where(aTributary ge 0.d, nTrib)
nTrib  = min([nTrib, 4]) ; try to have 4 tributaries
;print, 'nTrib = ', nTrib
if(nTrib eq 0)then begin
 networkSubset = ixSubset
 return 
endif

; sort tributaries
ixSort = reverse( sort(aTributary[ixTrib]) )
ixJunc = ixTrib[ixSort[0:nTrib-1]]
if keyword_set(iPrint) then print, 'aTributary = ', aTributary[ixTrib[ixSort]]

; sort junctions
if(stddev(totalArea_mizu[mainSubset]) gt 1.d)then begin
 iySort = reverse( sort(totalArea_mizu[mainSubset[ixJunc]]) )  ; sort by area
endif else begin
 iySort = sort(ixJunc)  ; sort by index
endelse

; get indices of junctions
iyJunc = mainSubset[ixJunc[iySort]]

; print
if keyword_set(iPrint) then begin
 print, '**'
 print, 'nTrib     = ', nTrib
 print, 'trib Area = ', aTributary[ixJunc]
 print, 'stem Area = ', totalArea_mizu[iyJunc]
 print, 'ixJunc    = ', ixJunc
 print, 'iyJunc    = ', iyJunc
 print, 'segMin    = ', segSave
 print, 'segMax    = ', segMax
endif

; re-initialize mainstem
iSeg = segSave

; define junctions
lastPoint = n_elements(iyJunc)*2-1
izTemp    = [0,0,1,1,2,2,3,3]
izJunc    = [[izTemp[0:lastPoint]],transpose([izTemp[lastPoint]])]
;print, 'iyJunc = ', iyJunc[izJunc]

; loop through the largest 4 tributaries
for pCode=1,nTrib*2+1 do begin

 ; define pfafstetter index
 iJunc = iyJunc[izJunc[pCode-1]]

 ; *** main stem and below headwater stem
 if(pCode mod 2 ne 0 and pCode lt nTrib*2+1)then begin

  ; handle special case where two tributaries are in the same reach (nothing on the main stem)
  if(pCode gt 1)then begin
   if(iJunc eq iyJunc[izJunc[pCode-2]])then continue
  endif

  if keyword_set(iPrint) then print, 'getting stem: pCode, iSeg, iJunc = ', pCode, iSeg, iJunc 
  ; crawl upstream -- main stem -- crawl to the next junction
  crawlUpstream, iSeg, iJunc, pCode, upSeg_count, upsReach, totalArea_mizu, ixAssign, $  ; input
                 mainSubset, ixMainstem                                                  ; output
  if keyword_set(iPrint) then print, 'pCode = ', pCode, ': ', ixMainstem[mainSubset]
  if keyword_set(iPrint) then print, 'pCode = ', pCode, ': ', mainSubset

 ; *** tributary or headwater stem
 endif else begin

  ; define a tributary: note: above the junction
  ixUps   = (*(upsReach[iJunc])).upSegIndices
  uArea   = totalArea_mizu[ixUps]
  kSort   = sort(uArea)

  ; identify the tributary
  if(pCode mod 2 ne 0)then begin
   iWant = kSort[n_elements(ixUps)-1]  ; main stem
  endif else begin
   ;print, '## getting feeders'
   ;print, 'ixAssign[ixUps] = ', ixAssign[ixUps]
   ;print, 'pfafVec[ixUps]  = ', pfafVec[ixUps]
   iFeed = where(ixAssign[ixUps] eq 0, nFeed)
   if(nFeed eq 0)then stop, 'expect at least one unassigned tributary'
   xArea = max(uArea[iFeed], iArea)
   iWant = iFeed[iArea]  ; unassigned tributary with the largest area
  endelse

  ; check that the tributary is needed
  if(ixAssign[ixUps[iWant]] eq 1)then begin
   nDig1 = ceil(alog10(pfafVec[ixUps[iWant]]))  ; number of digits in the upstream code
   nDig2 = ceil(alog10(pfafVec[segMin]))        ; number of digits in the downstream code
   iMult = 10^(nDig2 - nDig1)                   ; multiplier applied to upstream code
   if(pfafVec[ixUps[iWant]]*iMult gt pfafVec[segMin])then begin
    ;print, '### breaking!'
    break
   endif
  endif

  ; *** define the start index
  iSeg   = ixUps[iWant]

  ; *** define the end index
  if(pCode mod 2 ne 0)then begin ; headwater tributary

   ; segMax = headwater tributary, then go all the way to segMax
   if(upSeg_count[segMax] eq 0)then begin
    iTarget=segMax
   endif else begin

    ; check if flow from upstream (pfaf code above segMax > pfaf code at segMin)
    jxUps = (*(upsReach[segMax])).upSegIndices
    xArea = max(totalArea_mizu[jxUps], iArea)
    nDig1 = ceil(alog10(pfafVec[jxUps[iArea]]))  ; number of digits in the upstream code
    nDig2 = ceil(alog10(pfafVec[segMin]))        ; number of digits in the downstream code
    iMult = 10^(nDig2 - nDig1)                   ; multiplier aaplied to upsteam code
    if keyword_set(iPrint) then print, 'iMult = ', iMult
    if keyword_set(iPrint) then print, 'jxUps = ', jxUps
    if keyword_set(iPrint) then print, 'jxUps[iArea] = ', jxUps[iArea]
    if keyword_set(iPrint) then print, 'pfafVec[jxUps[iArea]]*iMult, pfafVec[segMin] = ', pfafVec[jxUps[iArea]]*iMult, pfafVec[segMin]
    if(ixAssign[jxUps[iArea]] eq 1 and pfafVec[jxUps[iArea]]*iMult gt pfafVec[segMin])then begin
     iTarget=segMax  ; inflow from upstream

    ; no flow from upstream -- go all the way to the top
    endif else begin
     iTarget=-9999   ; headwater tributary
    endelse  ; no flow from upstream

   endelse  ; not a headwater tributary

  ; one of the main tributaries (2,4,6,8)
  endif else begin
   iTarget=-9999   ; tributary: crawl all the way to the top
  endelse

  if keyword_set(iPrint) then print, 'getting trib: pCode, iSeg, iTarget = ', pCode, iSeg, iTarget 
  ;print, 'ixAssign[ixUps] = ', ixAssign[ixUps]
  ;print, 'pfafVec[ixUps]  = ', pfafVec[ixUps]
  ; crawl up a tributary
  crawlUpstream, iSeg, iTarget, pCode, upSeg_count, upsReach, totalArea_mizu, ixAssign, $  ; input
                 mainSubset, ixMainstem                                                    ; output
  ;print, 'pCode = ', pCode, ': ', ixMainstem[mainSubset]
  ;print, 'pCode = ', pCode, ': ', mainSubset

  ; update iSeg for the main stem (next loop iteration)
  if(pCode lt nTrib*2+1)then begin
   iArea = kSort[n_elements(ixUps)-1]
   iSeg  = ixUps[iArea]   ; NOTE: largest area
  endif

 endelse  ; if a tributary

 ;print, pCode, ': ', mainSubset

 ; save the indices of the subset
 if(pCode eq 1)then networkSubset = mainSubset else networkSubset = [networkSubset,mainSubset]
 ixAssign[mainSubset] = 1

endfor ; looping through tributaries

end
