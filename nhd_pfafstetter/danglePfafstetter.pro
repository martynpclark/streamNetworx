pro danglePfafstetter, iLevel, jDangle, pCode, segId_mizu, upSeg_count, upsReach, totalArea_mizu, $  ; input
                       mainStem, pfafVec                                                             ; output

; Used to compute pfafstetter indices for a given dangling reach

; input:
;  iLevel         (integer)   : start level
;  jDangle        (integer)   : start index
;  pCode          (int vec)   : vector of pfafstetter indices
;  segId_mizu     (int vec)   : id of each reach
;  upSeg_count    (int vec)   : number of reaches upstream of each reach
;  upsReach       (structure) : indices of upstream reaches
;  totalArea_mizu (real vec)  : upstream area above each reach
;  ixAssign       (int vec)   : flag defining if reach is assigned

; output:
;  mainStem       (int array) : pfafstetter code for each level
;  pfafVec        (int vec)   : pfafstetter code

; get the number of segments
nSeg = n_elements(totalArea_mizu)

; define arrays
ixSubset   = long64(lindgen(nSeg))
ixMainstem = replicate(-9999LL, nSeg)

; define the reaches assigned
ixAssign   = replicate(0L, nSeg)

; define the maximum level
maxLevel = n_elements(pCode)

; ---------- level 1 -------------------------------------------------------------------------------------------------

; define min and max segment
segMin = jDangle
segMax = -9999

; initialize with the main stem above the dangling reach
crawlUpstream, segMin, segMax, pCode[iLevel], upSeg_count, upsReach, totalArea_mizu, ixAssign, $  ; input
               ixSubset, ixMainstem                                                               ; output
; define the subset
ixSubset0 = ixSubset 
numSubset = n_elements(ixSubset)
if(numSubset eq 0)then stop, 'no valid reaches in the main stem on the first level'

; save the main stem
;  - get the first level
if(iLevel eq 0)then begin
 mainStem[iLevel,ixSubset] = ixMainstem[ixSubset]

;  - include all levels before the start of network navigation
endif else begin
 mainStem[0:iLevel,ixSubset] = [rebin(pCode[0:iLevel-1], ilevel, numSubset), transpose(ixMainstem[ixSubset])]
endelse

; identify the subset processed
ixAssign[ixSubset] = 1

; get the pfafstetter code
iPower  = 10LL^reverse(long64(lindgen(iLevel+1)))
iVector = long64(mainStem[0:iLevel,ixSubset])
if(numSubset eq 1)then pfafVec[ixSubset] = total(iPower*iVector, /integer) $ ; scalar operation
                  else pfafVec[ixSubset] = reform(iPower#iVector)            ; vector operation

; save Pfaf code
iLevel = iLevel+1

; get the new subset
ixTemp = where(reform(mainStem[iLevel-1,ixSubset0]) eq pCode[iLevel-1], nSubset)
if(nSubset eq 0)then stop, 'cannot identify pfafstetter codes for the first level'
ixSubset = ixSubset0[ixTemp]

; get Pfafstetter code for a given level
get_pfafsCode, pfafVec, segId_mizu, upSeg_count, upsReach, totalArea_mizu, ixAssign, ixSubset, $  ; input
               networkSubset, ixMainstem, nTrib                                                    ; output

; save the subset
ixSubset1 = networkSubset
numSubset = n_elements(networkSubset)
if(numSubset gt 0 and nTrib gt 0)then begin

 ; assign main stem
 ixAssign[networkSubset]          = 1  
 mainStem[0:iLevel,networkSubset] = [rebin(pCode[0:iLevel-1], ilevel, numSubset), transpose(ixMainstem[networkSubset])]
 ;print, byte(mainstem[0:iLevel,networkSubset])

 ; get pfafstetter code
 iPower  = 10LL^reverse(long64(lindgen(iLevel+1)))
 iVector = long64(mainStem[0:iLevel,networkSubset])
 if(numSubset eq 1)then pfafVec[networkSubset] = total(iPower*iVector, /integer) $ ; scalar operation
                   else pfafVec[networkSubset] = reform(iPower#iVector)            ; vector operation

endif

ixCheckOverwrite = where(ixMainstem eq 9)

; ---------- level 2 -------------------------------------------------------------------------------------------------

; loop through subsequent pfafstetter levels
for pCode2=1,9 do begin

 ;if(pcode2 ne 2)then continue

 ; save Pfaf code
 pCode[iLevel]     = pCode2
 iLevel            = iLevel+1

 ; get the new subset
 ixTemp = where(reform(mainStem[iLevel-1,ixSubset1]) eq pCode[iLevel-1], nSubset)
 if(nSubset eq 0)then begin
  iLevel = iLevel-1
  continue
 endif
 ixSubset = ixSubset1[ixTemp]

 ; get Pfafstetter code for a given level
 get_pfafsCode, pfafVec, segId_mizu, upSeg_count, upsReach, totalArea_mizu, ixAssign, ixSubset, $  ; input
                networkSubset, ixMainstem, nTrib                                                    ; output

 ; save the subset
 ixSubset2 = networkSubset
 numSubset = n_elements(networkSubset)
 if(numSubset gt 0 and nTrib gt 0)then begin

  ; assign main stem
  ixAssign[networkSubset]          = 1  
  mainStem[0:iLevel,networkSubset] = [rebin(pCode[0:iLevel-1], ilevel, numSubset), transpose(ixMainstem[networkSubset])]
  ;print, byte(mainstem[0:iLevel,networkSubset])

  ; get pfafstetter code
  iPower  = 10LL^reverse(long64(lindgen(iLevel+1)))
  iVector = long64(mainStem[0:iLevel,networkSubset])
  if(numSubset eq 1)then pfafVec[networkSubset] = total(iPower*iVector, /integer) $ ; scalar operation
                    else pfafVec[networkSubset] = reform(iPower#iVector)            ; vector operation
 endif

 ; skip subsequent loops if the level is too high
 if(iLevel ge maxLevel-1)then begin
  iLevel = iLevel-1
  continue
 endif

 ; ---------- level 3 -------------------------------------------------------------------------------------------------

 ; loop through subsequent pfafstetter levels
 for pCode3=1,9 do begin

  ;if(pcode3 ne 1)then continue

  ; save Pfaf code
  pCode[iLevel]     = pCode3
  iLevel            = iLevel+1
  ;print, 'level 3: pCode = ', byte(pCode[0:iLevel-1])

  ; get the new subset
  ixTemp = where(reform(mainStem[iLevel-1,ixSubset2]) eq pCode[iLevel-1], nSubset)
  if(nSubset eq 0)then begin
   iLevel = iLevel-1
   continue
  endif
  ixSubset = ixSubset2[ixTemp]

  ; get Pfafstetter code for a given level
  get_pfafsCode, pfafVec, segId_mizu, upSeg_count, upsReach, totalArea_mizu, ixAssign, ixSubset, $  ; input
                 networkSubset, ixMainstem, nTrib                                                    ; output

  ; save the subset
  ixSubset3 = networkSubset
  numSubset = n_elements(networkSubset)
  if(numSubset gt 0 and nTrib gt 0)then begin

   ; assign main stem
   ixAssign[networkSubset]          = 1  
   mainStem[0:iLevel,networkSubset] = [rebin(pCode[0:iLevel-1], ilevel, numSubset), transpose(ixMainstem[networkSubset])]
   ;print, [mainstem[0:iLevel,networkSubset], transpose(networkSubset)], format='(7(i1,1x),i20)'

   ; get pfafstetter code
   iPower  = 10LL^reverse(long64(lindgen(iLevel+1)))
   iVector = long64(mainStem[0:iLevel,networkSubset])
   if(numSubset eq 1)then pfafVec[networkSubset] = total(iPower*iVector, /integer) $ ; scalar operation
                     else pfafVec[networkSubset] = reform(iPower#iVector)            ; vector operation
  endif
  ;print, 'check data ', segId_mizu[ixTest], totalArea_mizu[ixTest], mainstem[0:iLevel,ixTest], format='(a,1x,i20,1x,f20.1,1x,10(i1,1x))'

  ; skip subsequent loops if the level is too high
  if(iLevel ge maxLevel-1)then begin
   iLevel = iLevel-1
   continue
  endif

  ; ---------- level 4 -------------------------------------------------------------------------------------------------

  ; loop through subsequent pfafstetter levels
  for pCode4=1,9 do begin

   ;if(pcode4 ne 5)then continue

   ; save Pfaf code
   pCode[iLevel]     = pCode4
   iLevel            = iLevel+1
   ;print, 'level 4: pCode = ', byte(pCode[0:iLevel-1])

   ; get the new subset
   ixTemp = where(reform(mainStem[iLevel-1,ixSubset3]) eq pCode[iLevel-1], nSubset)
   if(nSubset eq 0)then begin
    iLevel = iLevel-1
    continue
   endif
   ixSubset = ixSubset3[ixTemp]

   ; get Pfafstetter code for a given level
   get_pfafsCode, pfafVec, segId_mizu, upSeg_count, upsReach, totalArea_mizu, ixAssign, ixSubset, $  ; input
                  networkSubset, ixMainstem, nTrib;, /iPrint                                          ; output

   ; save the subset
   ixSubset4 = networkSubset
   numSubset = n_elements(networkSubset)
   if(numSubset gt 0 and nTrib gt 0)then begin

    ; assign main stem
    ixAssign[networkSubset]          = 1  
    mainStem[0:iLevel,networkSubset] = [rebin(pCode[0:iLevel-1], ilevel, numSubset), transpose(ixMainstem[networkSubset])]
    ;print, byte(mainstem[0:iLevel,networkSubset])

    ; get pfafstetter code
    iPower  = 10LL^reverse(long64(lindgen(iLevel+1)))
    iVector = long64(mainStem[0:iLevel,networkSubset])
    if(numSubset eq 1)then pfafVec[networkSubset] = total(iPower*iVector, /integer) $ ; scalar operation
                      else pfafVec[networkSubset] = reform(iPower#iVector)            ; vector operation

   endif
   ;print, 'check data ', segId_mizu[ixTest], totalArea_mizu[ixTest], mainstem[0:iLevel,ixTest], format='(a,1x,i20,1x,f20.1,1x,10(i1,1x))'

   ; skip subsequent loops if the level is too high
   if(iLevel ge maxLevel-1)then begin
    iLevel = iLevel-1
    continue
   endif

   ; ---------- level 5 -------------------------------------------------------------------------------------------------

   ; loop through subsequent pfafstetter levels
   for pCode5=1,9 do begin

    ;continue
    ;if(pcode5 ne 7)then continue

    ; save Pfaf code
    pCode[iLevel]     = pCode5
    iLevel            = iLevel+1
    ;print, 'level 5: pCode = ', byte(pCode[0:iLevel-1])

    ; get the new subset
    ixTemp = where(reform(mainStem[iLevel-1,ixSubset4]) eq pCode[iLevel-1], nSubset)
    if(nSubset eq 0)then begin
     iLevel = iLevel-1
     continue
    endif
    ixSubset = ixSubset4[ixTemp]

    ; get Pfafstetter code for a given level
    get_pfafsCode, pfafVec, segId_mizu, upSeg_count, upsReach, totalArea_mizu, ixAssign, ixSubset, $  ; input
                   networkSubset, ixMainstem, nTrib                                                    ; output

    ; save the subset
    ixSubset5 = networkSubset
    numSubset = n_elements(networkSubset)
    if(numSubset gt 0 and nTrib gt 0)then begin

     ; assign main stem
     ixAssign[networkSubset]          = 1  
     mainStem[0:iLevel,networkSubset] = [rebin(pCode[0:iLevel-1], ilevel, numSubset), transpose(ixMainstem[networkSubset])]
     ;print, byte(mainstem[0:iLevel,networkSubset])

     ; get pfafstetter code
     iPower  = 10LL^reverse(long64(lindgen(iLevel+1)))
     iVector = long64(mainStem[0:iLevel,networkSubset])
     if(numSubset eq 1)then pfafVec[networkSubset] = total(iPower*iVector, /integer) $ ; scalar operation
                       else pfafVec[networkSubset] = reform(iPower#iVector)            ; vector operation
    endif
    ;print, 'mainstem = '
    ;print, [byte(mainstem[0:iLevel,networkSubset]), transpose(segId_mizu[networkSubset])]
    ;print, 'check data ', segId_mizu[ixTest], totalArea_mizu[ixTest], mainstem[0:iLevel,ixTest], format='(a,1x,i20,1x,f20.1,1x,10(i1,1x))'

    ; skip subsequent loops if the level is too high
    if(iLevel ge maxLevel-1)then begin
     iLevel = iLevel-1
     continue
    endif

    ; ---------- level 6 -------------------------------------------------------------------------------------------------
 
    ; loop through subsequent pfafstetter levels
    for pCode6=1,9 do begin
 
     ;if(pcode6 ne 7)then continue

     ; save Pfaf code
     pCode[iLevel]     = pCode6
     iLevel            = iLevel+1
     ;print, 'level 6: pCode = ', byte(pCode[0:iLevel-1])
 
     ; get the new subset
     ixTemp = where(reform(mainStem[iLevel-1,ixSubset5]) eq pCode[iLevel-1], nSubset)
     if(nSubset eq 0)then begin
      iLevel = iLevel-1
      continue
     endif
     ixSubset = ixSubset5[ixTemp]
 
     ; get Pfafstetter code for a given level
     get_pfafsCode, pfafVec, segId_mizu, upSeg_count, upsReach, totalArea_mizu, ixAssign, ixSubset, $  ; input
                    networkSubset, ixMainstem, nTrib                                                    ; output
 
     ; save the subset
     ixSubset6 = networkSubset
     numSubset = n_elements(networkSubset)
     if(numSubset gt 0 and nTrib gt 0)then begin

      ; assign main stem
      ixAssign[networkSubset]          = 1  
      mainStem[0:iLevel,networkSubset] = [rebin(pCode[0:iLevel-1], ilevel, numSubset), transpose(ixMainstem[networkSubset])]
      ;print, byte(mainstem[0:iLevel,networkSubset])

      ; get pfafstetter code
      iPower  = 10LL^reverse(long64(lindgen(iLevel+1)))
      iVector = long64(mainStem[0:iLevel,networkSubset])
      if(numSubset eq 1)then pfafVec[networkSubset] = total(iPower*iVector, /integer) $ ; scalar operation
                        else pfafVec[networkSubset] = reform(iPower#iVector)            ; vector operation
     endif
     ;print, 'mainstem = '
     ;print, [byte(mainstem[0:iLevel,networkSubset]), transpose(segId_mizu[networkSubset])]
     ;print, 'check data ', segId_mizu[ixTest], totalArea_mizu[ixTest], mainstem[0:iLevel,ixTest], format='(a,1x,i20,1x,f20.1,1x,10(i1,1x))'

     ;if(pCode6 eq 9)then goto, done_it

     ; skip subsequent loops if the level is too high
     if(iLevel ge maxLevel-1)then begin
      iLevel = iLevel-1
      continue
     endif

     ; ---------- level 7 -------------------------------------------------------------------------------------------------

     ; loop through subsequent pfafstetter levels
     for pCode7=1,9 do begin

      ;if(pcode7 ne 5)then continue

      ; save Pfaf code
      pCode[iLevel]     = pCode7
      iLevel            = iLevel+1
      ;print, 'level 7: pCode = ', byte(pCode[0:iLevel-1])

      ; get the new subset
      ixTemp = where(reform(mainStem[iLevel-1,ixSubset6]) eq pCode[iLevel-1], nSubset)
      ;print, 'segId_mizu = ', segId_mizu[ixSubset6]
      if(nSubset eq 0)then begin
       iLevel = iLevel-1
       continue
      endif
      ixSubset = ixSubset6[ixTemp]
      ;print, 'segId_mizu = ', segId_mizu[ixSubset]

      ; get Pfafstetter code for a given level
      get_pfafsCode, pfafVec, segId_mizu, upSeg_count, upsReach, totalArea_mizu, ixAssign, ixSubset, $  ; input
                     networkSubset, ixMainstem, nTrib                                                    ; output

      ; save the subset
      ixSubset7 = networkSubset
      numSubset = n_elements(networkSubset)
      if(numSubset gt 0 and nTrib gt 0)then begin

       ; assign main stem
       ixAssign[networkSubset]          = 1  
       mainStem[0:iLevel,networkSubset] = [rebin(pCode[0:iLevel-1], ilevel, numSubset), transpose(ixMainstem[networkSubset])]
       ;print, byte(mainstem[0:iLevel,networkSubset])

       ; get pfafstetter code
       iPower  = 10LL^reverse(long64(lindgen(iLevel+1)))
       iVector = long64(mainStem[0:iLevel,networkSubset])
       if(numSubset eq 1)then pfafVec[networkSubset] = total(iPower*iVector, /integer) $ ; scalar operation
                         else pfafVec[networkSubset] = reform(iPower#iVector)            ; vector operation
      endif
      ;print, 'mainstem = '
      ;print, [byte(mainstem[0:iLevel,networkSubset]), transpose(segId_mizu[networkSubset]), transpose(networkSubset)]

      ; skip subsequent loops if the level is too high
      if(iLevel ge maxLevel-1)then begin
       iLevel = iLevel-1
       continue
      endif
      ;stop

      ; ---------- level 8 -------------------------------------------------------------------------------------------------
 
      ; loop through subsequent pfafstetter levels
      for pCode8=1,9 do begin
 
       ;if(pcode8 ne 6)then continue

       ; save Pfaf code
       pCode[iLevel]     = pCode8
       iLevel            = iLevel+1
       ;print, 'level 8: pCode = ', byte(pCode[0:iLevel-1])

       ; get the new subset
       ixTemp = where(reform(mainStem[iLevel-1,ixSubset7]) eq pCode[iLevel-1], nSubset)
       if(nSubset eq 0)then begin
        iLevel = iLevel-1
        continue
       endif
       ixSubset = ixSubset7[ixTemp]

       ; get Pfafstetter code for a given level
       get_pfafsCode, pfafVec, segId_mizu, upSeg_count, upsReach, totalArea_mizu, ixAssign, ixSubset, $  ; input
                      networkSubset, ixMainstem, nTrib                                                    ; output
 
       ; save the subset
       ixSubset8 = networkSubset
       numSubset = n_elements(networkSubset)
       if(numSubset gt 0 and nTrib gt 0)then begin

        ; assign main stem
        ixAssign[networkSubset]          = 1  
        mainStem[0:iLevel,networkSubset] = [rebin(pCode[0:iLevel-1], ilevel, numSubset), transpose(ixMainstem[networkSubset])]
        ;print, byte(mainstem[0:iLevel,networkSubset])

        ; get pfafstetter code
        iPower  = 10LL^reverse(long64(lindgen(iLevel+1)))
        iVector = long64(mainStem[0:iLevel,networkSubset])
        if(numSubset eq 1)then pfafVec[networkSubset] = total(iPower*iVector, /integer) $ ; scalar operation
                          else pfafVec[networkSubset] = reform(iPower#iVector)            ; vector operation
       endif
       ;print, 'mainstem = '
       ;print, [byte(mainstem[0:iLevel,networkSubset]), transpose(segId_mizu[networkSubset])]

       ; skip subsequent loops if the level is too high
       if(iLevel ge maxLevel-1)then begin
        iLevel = iLevel-1
        continue
       endif

       ; ---------- level 9 -------------------------------------------------------------------------------------------------

       ; loop through subsequent pfafstetter levels
       for pCode9=1,9 do begin

        ;if(pcode8 ne 3)then continue

        ; save Pfaf code
        pCode[iLevel]     = pCode9
        iLevel            = iLevel+1
        ;print, 'level 9: pCode = ', byte(pCode[0:iLevel-1])

        ; get the new subset
        ixTemp = where(reform(mainStem[iLevel-1,ixSubset8]) eq pCode[iLevel-1], nSubset)
        if(nSubset eq 0)then begin
         iLevel = iLevel-1
         continue
        endif
        ixSubset = ixSubset8[ixTemp]

        ; get Pfafstetter code for a given level
        get_pfafsCode, pfafVec, segId_mizu, upSeg_count, upsReach, totalArea_mizu, ixAssign, ixSubset, $  ; input
                       networkSubset, ixMainstem, nTrib                                                    ; output

        ; save the subset
        ixSubset9 = networkSubset
        numSubset = n_elements(networkSubset)
        if(numSubset gt 0 and nTrib gt 0)then begin
         ; assign main stem
         ixAssign[networkSubset]          = 1  
         mainStem[0:iLevel,networkSubset] = [rebin(pCode[0:iLevel-1], ilevel, numSubset), transpose(ixMainstem[networkSubset])]
         ; get pfafstetter code
         iPower  = 10LL^reverse(long64(lindgen(iLevel+1)))
         iVector = long64(mainStem[0:iLevel,networkSubset])
         if(numSubset eq 1)then pfafVec[networkSubset] = total(iPower*iVector, /integer) $ ; scalar operation
                           else pfafVec[networkSubset] = reform(iPower#iVector)            ; vector operation
        endif
        ;print, 'mainstem = '
        ;print, byte(mainstem[0:iLevel,networkSubset])
        ;stop

        ; skip subsequent loops if the level is too high
        if(iLevel ge maxLevel-1)then begin
         iLevel = iLevel-1
         continue
        endif

        ; ---------- level 10 -------------------------------------------------------------------------------------------------

        ; loop through subsequent pfafstetter levels
        for pCode10=1,9 do begin

         ; save Pfaf code
         pCode[iLevel]     = pCode10
         iLevel            = iLevel+1

         ; get the new subset
         ixTemp = where(reform(mainStem[iLevel-1,ixSubset9]) eq pCode[iLevel-1], nSubset)
         if(nSubset eq 0)then begin
          iLevel = iLevel-1
          continue
         endif
         ixSubset = ixSubset9[ixTemp]

         ; get Pfafstetter code for a given level
         get_pfafsCode, pfafVec, segId_mizu, upSeg_count, upsReach, totalArea_mizu, ixAssign, ixSubset, $  ; input
                        networkSubset, ixMainstem, nTrib                                                    ; output

         ; save the subset
         ixSubset10 = networkSubset
         numSubset = n_elements(networkSubset)
         if(numSubset gt 0 and nTrib gt 0)then begin
          ; assign main stem
          ixAssign[networkSubset]          = 1  
          mainStem[0:iLevel,networkSubset] = [rebin(pCode[0:iLevel-1], ilevel, numSubset), transpose(ixMainstem[networkSubset])]
          ; get pfafstetter code
          iPower  = 10LL^reverse(long64(lindgen(iLevel+1)))
          iVector = long64(mainStem[0:iLevel,networkSubset])
          if(numSubset eq 1)then pfafVec[networkSubset] = total(iPower*iVector, /integer) $ ; scalar operation
                            else pfafVec[networkSubset] = reform(iPower#iVector)            ; vector operation
         endif

         ; skip subsequent loops if the level is too high
         if(iLevel ge maxLevel-1)then begin
          iLevel = iLevel-1
          continue
         endif

         ; ---------- level 11 -------------------------------------------------------------------------------------------------
 
         ; loop through subsequent pfafstetter levels
         for pCode11=1,9 do begin
 
          ; save Pfaf code
          pCode[iLevel]     = pCode11
          iLevel            = iLevel+1
 
          ; get the new subset
          ixTemp = where(reform(mainStem[iLevel-1,ixSubset10]) eq pCode[iLevel-1], nSubset)
          if(nSubset eq 0)then begin
           iLevel = iLevel-1
           continue
          endif
          ixSubset = ixSubset10[ixTemp]
 
          ; get Pfafstetter code for a given level
          get_pfafsCode, pfafVec, segId_mizu, upSeg_count, upsReach, totalArea_mizu, ixAssign, ixSubset, $  ; input
                         networkSubset, ixMainstem, nTrib                                                    ; output
 
          ; save the subset
          ixSubset11 = networkSubset
          numSubset = n_elements(networkSubset)
          if(numSubset gt 0 and nTrib gt 0)then begin
           ; assign main stem
           ixAssign[networkSubset]          = 1  
           mainStem[0:iLevel,networkSubset] = [rebin(pCode[0:iLevel-1], ilevel, numSubset), transpose(ixMainstem[networkSubset])]
           ; get pfafstetter code
           iPower  = 10LL^reverse(long64(lindgen(iLevel+1)))
           iVector = long64(mainStem[0:iLevel,networkSubset])
           if(numSubset eq 1)then pfafVec[networkSubset] = total(iPower*iVector, /integer) $ ; scalar operation
                             else pfafVec[networkSubset] = reform(iPower#iVector)            ; vector operation
          endif

          ; skip subsequent loops if the level is too high
          if(iLevel ge maxLevel-1)then begin
           iLevel = iLevel-1
           continue
          endif

          ; ---------- level 12 -------------------------------------------------------------------------------------------------

          ; loop through subsequent pfafstetter levels
          for pCode12=1,9 do begin

           ; save Pfaf code
           pCode[iLevel]     = pCode12
           iLevel            = iLevel+1

           ; get the new subset
           ixTemp = where(reform(mainStem[iLevel-1,ixSubset11]) eq pCode[iLevel-1], nSubset)
           if(nSubset eq 0)then begin
            iLevel = iLevel-1
            continue
           endif
           ixSubset = ixSubset11[ixTemp]

           ; get Pfafstetter code for a given level
           get_pfafsCode, pfafVec, segId_mizu, upSeg_count, upsReach, totalArea_mizu, ixAssign, ixSubset, $  ; input
                          networkSubset, ixMainstem, nTrib                                                    ; output

           ; save the subset
           ixSubset12 = networkSubset
           numSubset = n_elements(networkSubset)
           if(numSubset gt 0 and nTrib gt 0)then begin
            ; assign main stem
            ixAssign[networkSubset]          = 1  
            mainStem[0:iLevel,networkSubset] = [rebin(pCode[0:iLevel-1], ilevel, numSubset), transpose(ixMainstem[networkSubset])]
            ; get pfafstetter code
            iPower  = 10LL^reverse(long64(lindgen(iLevel+1)))
            iVector = long64(mainStem[0:iLevel,networkSubset])
            if(numSubset eq 1)then pfafVec[networkSubset] = total(iPower*iVector, /integer) $ ; scalar operation
                              else pfafVec[networkSubset] = reform(iPower#iVector)            ; vector operation
           endif

           ; skip subsequent loops if the level is too high
           if(iLevel ge maxLevel-1)then begin
            iLevel = iLevel-1
            continue
           endif

           ; ---------- level 13 -------------------------------------------------------------------------------------------------
 
           ; loop through subsequent pfafstetter levels
           for pCode13=1,9 do begin
 
            ; save Pfaf code
            pCode[iLevel]     = pCode13
            iLevel            = iLevel+1
 
            ; get the new subset
            ixTemp = where(reform(mainStem[iLevel-1,ixSubset12]) eq pCode[iLevel-1], nSubset)
            if(nSubset eq 0)then begin
             iLevel = iLevel-1
             continue
            endif
            ixSubset = ixSubset12[ixTemp]
 
            ; get Pfafstetter code for a given level
            get_pfafsCode, pfafVec, segId_mizu, upSeg_count, upsReach, totalArea_mizu, ixAssign, ixSubset, $  ; input
                           networkSubset, ixMainstem, nTrib                                                    ; output
 
            ; save the subset
            ixSubset13 = networkSubset
            numSubset = n_elements(networkSubset)
            if(numSubset gt 0 and nTrib gt 0)then begin
             ; assign main stem
             ixAssign[networkSubset]          = 1  
             mainStem[0:iLevel,networkSubset] = [rebin(pCode[0:iLevel-1], ilevel, numSubset), transpose(ixMainstem[networkSubset])]
             ; get pfafstetter code
             iPower  = 10LL^reverse(long64(lindgen(iLevel+1)))
             iVector = long64(mainStem[0:iLevel,networkSubset])
             if(numSubset eq 1)then pfafVec[networkSubset] = total(iPower*iVector, /integer) $ ; scalar operation
                               else pfafVec[networkSubset] = reform(iPower#iVector)            ; vector operation
            endif
 
            ; skip subsequent loops if the level is too high
            if(iLevel ge maxLevel-1)then begin
             iLevel = iLevel-1
             continue
            endif

            ; ---------- level 14 -------------------------------------------------------------------------------------------------
  
            ; loop through subsequent pfafstetter levels
            for pCode14=1,9 do begin
  
             ; save Pfaf code
             pCode[iLevel]     = pCode14
             iLevel            = iLevel+1
  
             ; get the new subset
             ixTemp = where(reform(mainStem[iLevel-1,ixSubset13]) eq pCode[iLevel-1], nSubset)
             if(nSubset eq 0)then begin
              iLevel = iLevel-1
              continue
             endif
             ixSubset = ixSubset13[ixTemp]
  
             ; get Pfafstetter code for a given level
             get_pfafsCode, pfafVec, segId_mizu, upSeg_count, upsReach, totalArea_mizu, ixAssign, ixSubset, $  ; input
                            networkSubset, ixMainstem, nTrib                                                    ; output
  
             ; save the subset
             ixSubset14 = networkSubset
             numSubset = n_elements(networkSubset)
             if(numSubset gt 0 and nTrib gt 0)then begin
              ; assign main stem
              ixAssign[networkSubset]          = 1  
              mainStem[0:iLevel,networkSubset] = [rebin(pCode[0:iLevel-1], ilevel, numSubset), transpose(ixMainstem[networkSubset])]
              ; get pfafstetter code
              iPower  = 10LL^reverse(long64(lindgen(iLevel+1)))
              iVector = long64(mainStem[0:iLevel,networkSubset])
              if(numSubset eq 1)then pfafVec[networkSubset] = total(iPower*iVector, /integer) $ ; scalar operation
                                else pfafVec[networkSubset] = reform(iPower#iVector)            ; vector operation
             endif

             ; skip subsequent loops if the level is too high
             if(iLevel ge maxLevel-1)then begin
              iLevel = iLevel-1
              continue
             endif

             ; ---------- level 15 -------------------------------------------------------------------------------------------------

             ; loop through subsequent pfafstetter levels
             for pCode15=1,9 do begin

              ; save Pfaf code
              pCode[iLevel]     = pCode15
              iLevel            = iLevel+1

              ; get the new subset
              ixTemp = where(reform(mainStem[iLevel-1,ixSubset14]) eq pCode[iLevel-1], nSubset)
              if(nSubset eq 0)then begin
               iLevel = iLevel-1
               continue
              endif
              ixSubset = ixSubset14[ixTemp]

              ; get Pfafstetter code for a given level
              get_pfafsCode, pfafVec, segId_mizu, upSeg_count, upsReach, totalArea_mizu, ixAssign, ixSubset, $  ; input
                             networkSubset, ixMainstem, nTrib                                                    ; output

              ; save the subset
              ixSubset15 = networkSubset
              numSubset = n_elements(networkSubset)
              if(numSubset gt 0 and nTrib gt 0)then begin
               ; assign main stem
               ixAssign[networkSubset]          = 1  
               mainStem[0:iLevel,networkSubset] = [rebin(pCode[0:iLevel-1], ilevel, numSubset), transpose(ixMainstem[networkSubset])]
               ; get pfafstetter code
               iPower  = 10LL^reverse(long64(lindgen(iLevel+1)))
               iVector = long64(mainStem[0:iLevel,networkSubset])
               if(numSubset eq 1)then pfafVec[networkSubset] = total(iPower*iVector, /integer) $ ; scalar operation
                                 else pfafVec[networkSubset] = reform(iPower#iVector)            ; vector operation
              endif

              ; skip subsequent loops if the level is too high
              if(iLevel ge maxLevel-1)then begin
               iLevel = iLevel-1
               continue
              endif

              ; ---------- level 16 -------------------------------------------------------------------------------------------------

              ; loop through subsequent pfafstetter levels
              for pCode16=1,9 do begin

               ; save Pfaf code
               pCode[iLevel]     = pCode16
               iLevel            = iLevel+1

               ; get the new subset
               ixTemp = where(reform(mainStem[iLevel-1,ixSubset15]) eq pCode[iLevel-1], nSubset)
               if(nSubset eq 0)then begin
                iLevel = iLevel-1
                continue
               endif
               ixSubset = ixSubset15[ixTemp]

               ; get Pfafstetter code for a given level
               get_pfafsCode, pfafVec, segId_mizu, upSeg_count, upsReach, totalArea_mizu, ixAssign, ixSubset, $  ; input
                              networkSubset, ixMainstem, nTrib                                                    ; output

               ; save the subset
               ixSubset16 = networkSubset
               numSubset = n_elements(networkSubset)
               if(numSubset gt 0 and nTrib gt 0)then begin
                ; assign main stem
                ixAssign[networkSubset]          = 1  
                mainStem[0:iLevel,networkSubset] = [rebin(pCode[0:iLevel-1], ilevel, numSubset), transpose(ixMainstem[networkSubset])]
                ; get pfafstetter code
                iPower  = 10LL^reverse(long64(lindgen(iLevel+1)))
                iVector = long64(mainStem[0:iLevel,networkSubset])
                if(numSubset eq 1)then pfafVec[networkSubset] = total(iPower*iVector, /integer) $ ; scalar operation
                                  else pfafVec[networkSubset] = reform(iPower#iVector)            ; vector operation
               endif

               ; skip subsequent loops if the level is too high
               if(iLevel ge maxLevel-1)then begin
                iLevel = iLevel-1
                continue
               endif

               ; ---------- level 17 -------------------------------------------------------------------------------------------------
 
               ; loop through subsequent pfafstetter levels
               for pCode17=1,9 do begin
 
                ; save Pfaf code
                pCode[iLevel]     = pCode17
                iLevel            = iLevel+1
 
                ; get the new subset
                ixTemp = where(reform(mainStem[iLevel-1,ixSubset16]) eq pCode[iLevel-1], nSubset)
                if(nSubset eq 0)then begin
                 iLevel = iLevel-1
                 continue
                endif
                ixSubset = ixSubset16[ixTemp]
 
                ; get Pfafstetter code for a given level
                get_pfafsCode, pfafVec, segId_mizu, upSeg_count, upsReach, totalArea_mizu, ixAssign, ixSubset, $  ; input
                               networkSubset, ixMainstem, nTrib                                                    ; output
 
                ; save the subset
                ixSubset17 = networkSubset
                numSubset = n_elements(networkSubset)
                if(numSubset gt 0 and nTrib gt 0)then begin
                 ; assign main stem
                 ixAssign[networkSubset]          = 1  
                 mainStem[0:iLevel,networkSubset] = [rebin(pCode[0:iLevel-1], ilevel, numSubset), transpose(ixMainstem[networkSubset])]
                 ; get pfafstetter code
                 iPower  = 10LL^reverse(long64(lindgen(iLevel+1)))
                 iVector = long64(mainStem[0:iLevel,networkSubset])
                 if(numSubset eq 1)then pfafVec[networkSubset] = total(iPower*iVector, /integer) $ ; scalar operation
                                   else pfafVec[networkSubset] = reform(iPower#iVector)            ; vector operation
                endif

                ; skip subsequent loops if the level is too high
                if(iLevel ge maxLevel-1)then begin
                 iLevel = iLevel-1
                 continue
                endif

                ; ---------- level 18 -------------------------------------------------------------------------------------------------
  
                ; loop through subsequent pfafstetter levels
                for pCode18=1,9 do begin
  
                 ; save Pfaf code
                 pCode[iLevel]     = pCode18
                 iLevel            = iLevel+1
  
                 ; get the new subset
                 ixTemp = where(reform(mainStem[iLevel-1,ixSubset17]) eq pCode[iLevel-1], nSubset)
                 if(nSubset eq 0)then begin
                  iLevel = iLevel-1
                  continue
                 endif
                 ixSubset = ixSubset17[ixTemp]
  
                 ; get Pfafstetter code for a given level
                 get_pfafsCode, pfafVec, segId_mizu, upSeg_count, upsReach, totalArea_mizu, ixAssign, ixSubset, $  ; input
                                networkSubset, ixMainstem, nTrib                                                    ; output
  
                 ; save the subset
                 ixSubset18 = networkSubset
                 numSubset = n_elements(networkSubset)
                 if(numSubset gt 0 and nTrib gt 0)then begin
                  ; assign main stem
                  ixAssign[networkSubset]          = 1  
                  mainStem[0:iLevel,networkSubset] = [rebin(pCode[0:iLevel-1], ilevel, numSubset), transpose(ixMainstem[networkSubset])]
                  ; get pfafstetter code
                  iPower  = 10LL^reverse(long64(lindgen(iLevel+1)))
                  iVector = long64(mainStem[0:iLevel,networkSubset])
                  if(numSubset eq 1)then pfafVec[networkSubset] = total(iPower*iVector, /integer) $ ; scalar operation
                                    else pfafVec[networkSubset] = reform(iPower#iVector)            ; vector operation
                 endif

                 ; skip subsequent loops if the level is too high
                 if(iLevel ge maxLevel-1)then begin
                  iLevel = iLevel-1
                  continue
                 endif

                 ; decrement level
                 iLevel = iLevel-1

                endfor  ; pfafstetter level 18

                ; decrement level
                iLevel = iLevel-1

               endfor  ; pfafstetter level 17

               ; decrement level
               iLevel = iLevel-1

              endfor  ; pfafstetter level 16

              ; decrement level
              iLevel = iLevel-1

             endfor  ; pfafstetter level 15

             ; decrement level
             iLevel = iLevel-1

            endfor  ; pfafstetter level 14

            ; decrement level
            iLevel = iLevel-1

           endfor  ; pfafstetter level 13

           ; decrement level
           iLevel = iLevel-1

          endfor  ; pfafstetter level 12

          ; decrement level
          iLevel = iLevel-1

         endfor  ; pfafstetter level 11

         ; decrement level
         iLevel = iLevel-1

        endfor  ; pfafstetter level 10

        ; decrement level
        iLevel = iLevel-1

       endfor  ; pfafstetter level 9

       ; decrement level
       iLevel = iLevel-1

      endfor  ; pfafstetter level 8

      ; decrement level
      iLevel = iLevel-1

     endfor  ; pfafstetter level 7

     ; decrement level
     iLevel = iLevel-1

    endfor  ; pfafstetter level 6

    ; decrement level
    iLevel = iLevel-1

   endfor  ; pfafstetter level 5

   ; decrement level
   iLevel = iLevel-1

  endfor  ; pfafstetter level 4

  ; decrement level
  iLevel = iLevel-1

 endfor  ; pfafstetter level 3

 ; decrement level
 iLevel = iLevel-1

endfor  ; pfafstetter level 2

; branch
done_it:

; check
;print, pfafVec[ixCheckOverwrite] 


end
