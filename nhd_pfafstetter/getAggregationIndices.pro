pro getAggregationIndices, basePfaf, ixInitial, pfafVec_string, basArea_mizu, downSegId_mizu, endLat, endLon, areaMin, areaMax, pfafId

; initialize counter
ixCount = 0

; define conversion factor (just for printing/debugging)
areaConv = 1.d+6

; define the largest area
areaBig = areaMax*1.d

; define initial Pfafstetter code
pCodeOld = basePfaf

; initialize structure containing valid indices
ixPfaf = create_struct('pfaf'+string(ixCount, format='(i2.2)'), ixInitial)

; initialize the areas for each Pfafstetter level
agArea = replicate(-9999.d, 20, 9)

; loop through Pfafstetter codes
for iPfaf1=0,9 do begin

 ; define pfaf code
 pCode  = pCodeOld + strtrim(iPfaf1,2)

 ; identify the subset
 ixSubset = where(strmid(pfafVec_string[ixPfaf.(ixCount)], 0, strlen(pCode)) eq pCode, nSubset)
 print, ixCount, ': '+ pCode, nSubset, total(basArea_mizu[ixPfaf.(ixCount)[ixSubset]]) / areaConv

 ; *****
 ; *****
 ; ***** new Pfafstetter level
 if(nSubset gt 0)then begin
  ixArea                 = fix(strmid(pCode, strlen(pCode)-1, 1))-1
  agArea[ixCount,ixArea] = total(basArea_mizu[ixPfaf.(ixCount)[ixSubset]])
  if(agArea[ixCount,ixArea] gt areaMax and nSubset ge 9)then begin
 
   ; update variables
   ixCount   = ixCount+1 
   pCodeOld  = pCode

   ; update the index structure
   ixPfaf = create_struct(ixPfaf, 'pfaf'+string(ixCount, format='(i2.2)'), ixPfaf.(ixCount-1)[ixSubset]) 

   ; loop through Pfafstetter codes
   for iPfaf2=0,9 do begin

    ; define pfaf code
    pCode  = pCodeOld + strtrim(iPfaf2,2)

    ; identify the subset
    ixSubset = where(strmid(pfafVec_string[ixPfaf.(ixCount)], 0, strlen(pCode)) eq pCode, nSubset)
    print, ixCount, ': '+ pCode, nSubset, total(basArea_mizu[ixPfaf.(ixCount)[ixSubset]]) / areaConv

    ; *****
    ; *****
    ; ***** new Pfafstetter level
    if(nSubset gt 0)then begin
     ixArea                 = fix(strmid(pCode, strlen(pCode)-1, 1))-1
     agArea[ixCount,ixArea] = total(basArea_mizu[ixPfaf.(ixCount)[ixSubset]])
     if(agArea[ixCount,ixArea] gt areaMax and nSubset ge 9)then begin
   
      ; update variables
      ixCount   = ixCount+1 
      pCodeOld  = pCode
   
      ; update the index structure
      ixPfaf = create_struct(ixPfaf, 'pfaf'+string(ixCount, format='(i2.2)'), ixPfaf.(ixCount-1)[ixSubset])
   
      ; loop through Pfafstetter codes
      for iPfaf3=0,9 do begin
   
       ; define pfaf code
       pCode  = pCodeOld + strtrim(iPfaf3,2)
   
       ; identify the subset
       ixSubset = where(strmid(pfafVec_string[ixPfaf.(ixCount)], 0, strlen(pCode)) eq pCode, nSubset)
       print, ixCount, ': '+ pCode, nSubset, total(basArea_mizu[ixPfaf.(ixCount)[ixSubset]]) / areaConv

       ; *****
       ; *****
       ; ***** new Pfafstetter level
       if(nSubset gt 0)then begin
        ixArea                 = fix(strmid(pCode, strlen(pCode)-1, 1))-1
        agArea[ixCount,ixArea] = total(basArea_mizu[ixPfaf.(ixCount)[ixSubset]])
        if(agArea[ixCount,ixArea] gt areaMax and nSubset ge 9)then begin
      
         ; update variables
         ixCount   = ixCount+1 
         pCodeOld  = pCode
      
         ; update the index structure
         ixPfaf = create_struct(ixPfaf, 'pfaf'+string(ixCount, format='(i2.2)'), ixPfaf.(ixCount-1)[ixSubset])
      
         ; loop through Pfafstetter codes
         for iPfaf4=0,9 do begin
      
          ; define pfaf code
          pCode  = pCodeOld + strtrim(iPfaf4,2)
      
          ; identify the subset
          ixSubset = where(strmid(pfafVec_string[ixPfaf.(ixCount)], 0, strlen(pCode)) eq pCode, nSubset)
          print, ixCount, ': '+ pCode, nSubset, total(basArea_mizu[ixPfaf.(ixCount)[ixSubset]]) / areaConv

          ; *****
          ; *****
          ; ***** new Pfafstetter level
          if(nSubset gt 0)then begin
           ixArea                 = fix(strmid(pCode, strlen(pCode)-1, 1))-1
           agArea[ixCount,ixArea] = total(basArea_mizu[ixPfaf.(ixCount)[ixSubset]])
           if(agArea[ixCount,ixArea] gt areaMax and nSubset ge 9)then begin
         
            ; update variables
            ixCount   = ixCount+1 
            pCodeOld  = pCode
         
            ; update the index structure
            ixPfaf = create_struct(ixPfaf, 'pfaf'+string(ixCount, format='(i2.2)'), ixPfaf.(ixCount-1)[ixSubset])
         
            ; loop through Pfafstetter codes
            for iPfaf5=0,9 do begin
         
             ; define pfaf code
             pCode  = pCodeOld + strtrim(iPfaf5,2)
         
             ; identify the subset
             ixSubset = where(strmid(pfafVec_string[ixPfaf.(ixCount)], 0, strlen(pCode)) eq pCode, nSubset)
             ;print, ixCount, ': '+ pCode, nSubset, total(basArea_mizu[ixPfaf.(ixCount)[ixSubset]]) / areaConv

             ; *****
             ; *****
             ; ***** new Pfafstetter level
             if(nSubset gt 0)then begin
              ixArea                 = fix(strmid(pCode, strlen(pCode)-1, 1))-1
              agArea[ixCount,ixArea] = total(basArea_mizu[ixPfaf.(ixCount)[ixSubset]])
              if(agArea[ixCount,ixArea] gt areaMax and nSubset ge 9)then begin
            
               ; update variables
               ixCount   = ixCount+1 
               pCodeOld  = pCode
            
               ; update the index structure
               ixPfaf = create_struct(ixPfaf, 'pfaf'+string(ixCount, format='(i2.2)'), ixPfaf.(ixCount-1)[ixSubset])
            
               ; loop through Pfafstetter codes
               for iPfaf6=0,9 do begin
            
                ; define pfaf code
                pCode  = pCodeOld + strtrim(iPfaf6,2)
            
                ; identify the subset
                ixSubset = where(strmid(pfafVec_string[ixPfaf.(ixCount)], 0, strlen(pCode)) eq pCode, nSubset)

                ; *****
                ; *****
                ; ***** new Pfafstetter level
                if(nSubset gt 0)then begin
                 ixArea                 = fix(strmid(pCode, strlen(pCode)-1, 1))-1
                 agArea[ixCount,ixArea] = total(basArea_mizu[ixPfaf.(ixCount)[ixSubset]])
                 if(agArea[ixCount,ixArea] gt areaMax and nSubset ge 9)then begin
               
                  ; update variables
                  ixCount   = ixCount+1 
                  pCodeOld  = pCode
               
                  ; update the index structure
                  ixPfaf = create_struct(ixPfaf, 'pfaf'+string(ixCount, format='(i2.2)'), ixPfaf.(ixCount-1)[ixSubset])
               
                  ; loop through Pfafstetter codes
                  for iPfaf7=0,9 do begin
               
                   ; define pfaf code
                   pCode  = pCodeOld + strtrim(iPfaf7,2)
               
                   ; identify the subset
                   ixSubset = where(strmid(pfafVec_string[ixPfaf.(ixCount)], 0, strlen(pCode)) eq pCode, nSubset)

                   ; *****
                   ; *****
                   ; ***** new Pfafstetter level
                   if(nSubset gt 0)then begin
                    ixArea                 = fix(strmid(pCode, strlen(pCode)-1, 1))-1
                    agArea[ixCount,ixArea] = total(basArea_mizu[ixPfaf.(ixCount)[ixSubset]])
                    if(agArea[ixCount,ixArea] gt areaMax and nSubset ge 9)then begin
                  
                     ; update variables
                     ixCount   = ixCount+1 
                     pCodeOld  = pCode
                  
                     ; update the index structure
                     ixPfaf = create_struct(ixPfaf, 'pfaf'+string(ixCount, format='(i2.2)'), ixPfaf.(ixCount-1)[ixSubset])
                  
                     ; loop through Pfafstetter codes
                     for iPfaf8=0,9 do begin
                  
                      ; define pfaf code
                      pCode  = pCodeOld + strtrim(iPfaf8,2)
                  
                      ; identify the subset
                      ixSubset = where(strmid(pfafVec_string[ixPfaf.(ixCount)], 0, strlen(pCode)) eq pCode, nSubset)

                      ; *****
                      ; *****
                      ; ***** new Pfafstetter level
                      if(nSubset gt 0)then begin
                       ixArea                 = fix(strmid(pCode, strlen(pCode)-1, 1))-1
                       agArea[ixCount,ixArea] = total(basArea_mizu[ixPfaf.(ixCount)[ixSubset]])
                       if(agArea[ixCount,ixArea] gt areaMax and nSubset ge 9)then begin
                     
                        ; update variables
                        ixCount   = ixCount+1 
                        pCodeOld  = pCode
                     
                        ; update the index structure
                        ixPfaf = create_struct(ixPfaf, 'pfaf'+string(ixCount, format='(i2.2)'), ixPfaf.(ixCount-1)[ixSubset])
                     
                        ; loop through Pfafstetter codes
                        for iPfaf9=0,9 do begin
                     
                         ; define pfaf code
                         pCode  = pCodeOld + strtrim(iPfaf9,2)
                     
                         ; identify the subset
                         ixSubset = where(strmid(pfafVec_string[ixPfaf.(ixCount)], 0, strlen(pCode)) eq pCode, nSubset)

                         ; *****
                         ; *****
                         ; ***** new Pfafstetter level
                         if(nSubset gt 0)then begin
                          ixArea                 = fix(strmid(pCode, strlen(pCode)-1, 1))-1
                          agArea[ixCount,ixArea] = total(basArea_mizu[ixPfaf.(ixCount)[ixSubset]])
                          if(agArea[ixCount,ixArea] gt areaMax and nSubset ge 9)then begin
                        
                           ; update variables
                           ixCount   = ixCount+1 
                           pCodeOld  = pCode
                        
                           ; update the index structure
                           ixPfaf = create_struct(ixPfaf, 'pfaf'+string(ixCount, format='(i2.2)'), ixPfaf.(ixCount-1)[ixSubset])
                        
                           ; loop through Pfafstetter codes
                           for iPfaf10=0,9 do begin
                        
                            ; define pfaf code
                            pCode  = pCodeOld + strtrim(iPfaf10,2)
                        
                            ; identify the subset
                            ixSubset = where(strmid(pfafVec_string[ixPfaf.(ixCount)], 0, strlen(pCode)) eq pCode, nSubset)


                            ; *****
                            ; *****
                            ; ***** new Pfafstetter level
                            if(nSubset gt 0)then begin
                             ixArea                 = fix(strmid(pCode, strlen(pCode)-1, 1))-1
                             agArea[ixCount,ixArea] = total(basArea_mizu[ixPfaf.(ixCount)[ixSubset]])
                             if(agArea[ixCount,ixArea] gt areaMax and nSubset ge 9)then begin

                              ; update variables
                              ixCount   = ixCount+1 
                              pCodeOld  = pCode

                              ; update the index structure
                              ixPfaf = create_struct(ixPfaf, 'pfaf'+string(ixCount, format='(i2.2)'), ixPfaf.(ixCount-1)[ixSubset])

                              ; loop through Pfafstetter codes
                              for iPfaf11=0,9 do begin

                               ; define pfaf code
                               pCode  = pCodeOld + strtrim(iPfaf11,2)

                               ; identify the subset
                               ixSubset = where(strmid(pfafVec_string[ixPfaf.(ixCount)], 0, strlen(pCode)) eq pCode, nSubset)

                               ; *****
                               ; *****
                               ; ***** new Pfafstetter level
                               if(nSubset gt 0)then begin
                                ixArea                 = fix(strmid(pCode, strlen(pCode)-1, 1))-1
                                agArea[ixCount,ixArea] = total(basArea_mizu[ixPfaf.(ixCount)[ixSubset]])
                                if(agArea[ixCount,ixArea] gt areaMax and nSubset ge 9)then begin

                                 ; update variables
                                 ixCount   = ixCount+1 
                                 pCodeOld  = pCode

                                 ; update the index structure
                                 ixPfaf = create_struct(ixPfaf, 'pfaf'+string(ixCount, format='(i2.2)'), ixPfaf.(ixCount-1)[ixSubset])

                                 ; loop through Pfafstetter codes
                                 for iPfaf12=0,9 do begin

                                  ; define pfaf code
                                  pCode  = pCodeOld + strtrim(iPfaf12,2)

                                  ; identify the subset
                                  ixSubset = where(strmid(pfafVec_string[ixPfaf.(ixCount)], 0, strlen(pCode)) eq pCode, nSubset)

                                  ; *****
                                  ; *****
                                  ; ***** new Pfafstetter level
                                  if(nSubset gt 0)then begin
                                   ixArea                 = fix(strmid(pCode, strlen(pCode)-1, 1))-1
                                   agArea[ixCount,ixArea] = total(basArea_mizu[ixPfaf.(ixCount)[ixSubset]])
                                   if(agArea[ixCount,ixArea] gt areaMax and nSubset ge 9)then begin

                                    ; update variables
                                    ixCount   = ixCount+1 
                                    pCodeOld  = pCode

                                    ; update the index structure
                                    ixPfaf = create_struct(ixPfaf, 'pfaf'+string(ixCount, format='(i2.2)'), ixPfaf.(ixCount-1)[ixSubset])

                                    ; loop through Pfafstetter codes
                                    for iPfaf13=0,9 do begin

                                     ; define pfaf code
                                     pCode  = pCodeOld + strtrim(iPfaf13,2)

                                     ; identify the subset
                                     ixSubset = where(strmid(pfafVec_string[ixPfaf.(ixCount)], 0, strlen(pCode)) eq pCode, nSubset)

                                     ; *****
                                     ; *****
                                     ; ***** new Pfafstetter level
                                     if(nSubset gt 0)then begin
                                      ixArea                 = fix(strmid(pCode, strlen(pCode)-1, 1))-1
                                      agArea[ixCount,ixArea] = total(basArea_mizu[ixPfaf.(ixCount)[ixSubset]])
                                      if(agArea[ixCount,ixArea] gt areaMax and nSubset ge 9)then begin

                                       ; update variables
                                       ixCount   = ixCount+1 
                                       pCodeOld  = pCode

                                       ; update the index structure
                                       ixPfaf = create_struct(ixPfaf, 'pfaf'+string(ixCount, format='(i2.2)'), ixPfaf.(ixCount-1)[ixSubset])

                                       ; loop through Pfafstetter codes
                                       for iPfaf14=0,9 do begin

                                        ; define pfaf code
                                        pCode  = pCodeOld + strtrim(iPfaf14,2)

                                        ; identify the subset
                                        ixSubset = where(strmid(pfafVec_string[ixPfaf.(ixCount)], 0, strlen(pCode)) eq pCode, nSubset)

                                        ; *****
                                        ; *****
                                        ; ***** new Pfafstetter level
                                        if(nSubset gt 0)then begin
                                         ixArea                 = fix(strmid(pCode, strlen(pCode)-1, 1))-1
                                         agArea[ixCount,ixArea] = total(basArea_mizu[ixPfaf.(ixCount)[ixSubset]])
                                         if(agArea[ixCount,ixArea] gt areaMax and nSubset ge 9)then begin

                                          ; update variables
                                          ixCount   = ixCount+1 
                                          pCodeOld  = pCode

                                          ; update the index structure
                                          ixPfaf = create_struct(ixPfaf, 'pfaf'+string(ixCount, format='(i2.2)'), ixPfaf.(ixCount-1)[ixSubset])

                                          ; loop through Pfafstetter codes
                                          for iPfaf15=0,9 do begin

                                           ; define pfaf code
                                           pCode  = pCodeOld + strtrim(iPfaf15,2)

                                           ; identify the subset
                                           ixSubset = where(strmid(pfafVec_string[ixPfaf.(ixCount)], 0, strlen(pCode)) eq pCode, nSubset)

                                           ; *****
                                           ; *****
                                           ; ***** new Pfafstetter level
                                           if(nSubset gt 0)then begin
                                            ixArea                 = fix(strmid(pCode, strlen(pCode)-1, 1))-1
                                            agArea[ixCount,ixArea] = total(basArea_mizu[ixPfaf.(ixCount)[ixSubset]])
                                            if(agArea[ixCount,ixArea] gt areaMax and nSubset ge 9)then begin

                                             ; update variables
                                             ixCount   = ixCount+1 
                                             pCodeOld  = pCode

                                             ; update the index structure
                                             ixPfaf = create_struct(ixPfaf, 'pfaf'+string(ixCount, format='(i2.2)'), ixPfaf.(ixCount-1)[ixSubset])

                                             ; loop through Pfafstetter codes
                                             for iPfaf16=0,9 do begin

                                              ; define pfaf code
                                              pCode  = pCodeOld + strtrim(iPfaf16,2)

                                              ; identify the subset
                                              ixSubset = where(strmid(pfafVec_string[ixPfaf.(ixCount)], 0, strlen(pCode)) eq pCode, nSubset)

                                              ; *****
                                              ; *****
                                              ; ***** new Pfafstetter level
                                              if(nSubset gt 0)then begin
                                               ixArea                 = fix(strmid(pCode, strlen(pCode)-1, 1))-1
                                               agArea[ixCount,ixArea] = total(basArea_mizu[ixPfaf.(ixCount)[ixSubset]])
                                               if(agArea[ixCount,ixArea] gt areaMax and nSubset ge 9)then begin

                                                ; update variables
                                                ixCount   = ixCount+1 
                                                pCodeOld  = pCode

                                                ; update the index structure
                                                ixPfaf = create_struct(ixPfaf, 'pfaf'+string(ixCount, format='(i2.2)'), ixPfaf.(ixCount-1)[ixSubset])

                                                ; loop through Pfafstetter codes
                                                for iPfaf17=0,9 do begin

                                                 ; define pfaf code
                                                 pCode  = pCodeOld + strtrim(iPfaf17,2)

                                                 ; identify the subset
                                                 ixSubset = where(strmid(pfafVec_string[ixPfaf.(ixCount)], 0, strlen(pCode)) eq pCode, nSubset)

                                                 ; final level: assign Pfafstetter code
                                                 if(nSubset gt 0)then begin
                                                  ixArea                 = fix(strmid(pCode, strlen(pCode)-1, 1))-1
                                                  agArea[ixCount,ixArea] = total(basArea_mizu[ixPfaf.(ixCount)[ixSubset]])
                                                  aggregateReaches, ixPfaf.(ixCount)[ixSubset], pCode, downSegId_mizu, endLat, endLon, pfafId
                                                 endif else begin
                                                  stop, 'insufficient levels'
                                                 endelse

                                                endfor  ; looping through pfaf level 17

                                                ; correct minimum areas
                                                ixValid = where(agArea[ixCount,*] ge 0.d, nValid)
                                                if(nValid gt 0)then begin
                                                 if(min(agArea[ixCount,ixValid]) lt areaMin and total(agArea[ixCount,ixValid]) lt areaBig)then begin
                                                  aggregateReaches, ixPfaf.(ixCount), pCodeOld, downSegId_mizu, endLat, endLon, pfafId
                                                 endif
                                                endif
          
                                                ; decrement pCode and iCount
                                                agArea[ixCount,*] = -9999.d
                                                pCodeOld = strmid(pCodeOld,0,strlen(pCodeOld)-1)
                                                ixCount  = ixCount-1

                                                ; remove element from the structure
                                                struct = ixPfaf  ; a copy of the structure
                                                ixPfaf = create_struct('pfaf00', struct.(0))                
                                                for ix=1,n_tags(struct)-2 do ixPfaf = create_struct(ixPfaf, 'pfaf00'+string(ix, format='(i2.2)'), struct.(ix))

                                               ; area is not sufficient
                                               endif else begin
                                                aggregateReaches, ixPfaf.(ixCount)[ixSubset], pCode, downSegId_mizu, endLat, endLon, pfafId
                                                ;print, pCode, total(basArea_mizu[ixPfaf.(ixCount)[ixSubset]]), pfafVec_string[ixPfaf.(ixCount)[ixSubset]]
                                               endelse

                                              endif  ; if valid
                                              ; *****
                                              ; *****

                                             endfor  ; looping through pfaf level 16
                                            
                                             ; correct minimum areas
                                             ixValid = where(agArea[ixCount,*] ge 0.d, nValid)
                                             if(nValid gt 0)then begin
                                              if(min(agArea[ixCount,ixValid]) lt areaMin and total(agArea[ixCount,ixValid]) lt areaBig)then begin
                                               aggregateReaches, ixPfaf.(ixCount), pCodeOld, downSegId_mizu, endLat, endLon, pfafId
                                              endif
                                             endif
          
                                             ; decrement pCode and iCount
                                             agArea[ixCount,*] = -9999.d
                                             pCodeOld = strmid(pCodeOld,0,strlen(pCodeOld)-1)
                                             ixCount  = ixCount-1
                                            
                                             ; remove element from the structure
                                             struct = ixPfaf  ; a copy of the structure
                                             ixPfaf = create_struct('pfaf00', struct.(0))                
                                             for ix=1,n_tags(struct)-2 do ixPfaf = create_struct(ixPfaf, 'pfaf00'+string(ix, format='(i2.2)'), struct.(ix))
                                            
                                            ; area is not sufficient
                                            endif else begin
                                             aggregateReaches, ixPfaf.(ixCount)[ixSubset], pCode, downSegId_mizu, endLat, endLon, pfafId
                                             ;print, pCode, total(basArea_mizu[ixPfaf.(ixCount)[ixSubset]]), pfafVec_string[ixPfaf.(ixCount)[ixSubset]]
                                            endelse

                                           endif  ; if valid
                                           ; *****
                                           ; *****

                                          endfor  ; looping through pfaf level 15
                                        
                                          ; correct minimum areas
                                          ixValid = where(agArea[ixCount,*] ge 0.d, nValid)
                                          if(nValid gt 0)then begin
                                           if(min(agArea[ixCount,ixValid]) lt areaMin and total(agArea[ixCount,ixValid]) lt areaBig)then begin
                                            aggregateReaches, ixPfaf.(ixCount), pCodeOld, downSegId_mizu, endLat, endLon, pfafId
                                           endif
                                          endif
          
                                          ; decrement pCode and iCount
                                          agArea[ixCount,*] = -9999.d
                                          pCodeOld = strmid(pCodeOld,0,strlen(pCodeOld)-1)
                                          ixCount  = ixCount-1
                                        
                                          ; remove element from the structure
                                          struct = ixPfaf  ; a copy of the structure
                                          ixPfaf = create_struct('pfaf00', struct.(0))                
                                          for ix=1,n_tags(struct)-2 do ixPfaf = create_struct(ixPfaf, 'pfaf00'+string(ix, format='(i2.2)'), struct.(ix))
                                        
                                         ; area is not sufficient
                                         endif else begin
                                          aggregateReaches, ixPfaf.(ixCount)[ixSubset], pCode, downSegId_mizu, endLat, endLon, pfafId
                                          ;print, pCode, total(basArea_mizu[ixPfaf.(ixCount)[ixSubset]]), pfafVec_string[ixPfaf.(ixCount)[ixSubset]]
                                         endelse
                                        
                                        endif  ; if valid
                                        ; *****
                                        ; *****

                                       endfor  ; looping through pfaf level 14
                                     
                                       ; correct minimum areas
                                       ixValid = where(agArea[ixCount,*] ge 0.d, nValid)
                                       if(nValid gt 0)then begin
                                        if(min(agArea[ixCount,ixValid]) lt areaMin and total(agArea[ixCount,ixValid]) lt areaBig)then begin
                                         aggregateReaches, ixPfaf.(ixCount), pCodeOld, downSegId_mizu, endLat, endLon, pfafId
                                        endif
                                       endif
          
                                       ; decrement pCode and iCount
                                       agArea[ixCount,*] = -9999.d
                                       pCodeOld = strmid(pCodeOld,0,strlen(pCodeOld)-1)
                                       ixCount  = ixCount-1
                                     
                                       ; remove element from the structure
                                       struct = ixPfaf  ; a copy of the structure
                                       ixPfaf = create_struct('pfaf00', struct.(0))                
                                       for ix=1,n_tags(struct)-2 do ixPfaf = create_struct(ixPfaf, 'pfaf00'+string(ix, format='(i2.2)'), struct.(ix))
                                     
                                      ; area is not sufficient
                                      endif else begin
                                       aggregateReaches, ixPfaf.(ixCount)[ixSubset], pCode, downSegId_mizu, endLat, endLon, pfafId
                                       ;print, pCode, total(basArea_mizu[ixPfaf.(ixCount)[ixSubset]]), pfafVec_string[ixPfaf.(ixCount)[ixSubset]]
                                      endelse
                                     
                                     endif  ; if valid
                                     ; *****
                                     ; *****

                                    endfor  ; looping through pfaf level 13
                                  
                                    ; correct minimum areas
                                    ixValid = where(agArea[ixCount,*] ge 0.d, nValid)
                                    if(nValid gt 0)then begin
                                     if(min(agArea[ixCount,ixValid]) lt areaMin and total(agArea[ixCount,ixValid]) lt areaBig)then begin
                                      aggregateReaches, ixPfaf.(ixCount), pCodeOld, downSegId_mizu, endLat, endLon, pfafId
                                     endif
                                    endif
          
                                    ; decrement pCode and iCount
                                    agArea[ixCount,*] = -9999.d
                                    pCodeOld = strmid(pCodeOld,0,strlen(pCodeOld)-1)
                                    ixCount  = ixCount-1
                                  
                                    ; remove element from the structure
                                    struct = ixPfaf  ; a copy of the structure
                                    ixPfaf = create_struct('pfaf00', struct.(0))                
                                    for ix=1,n_tags(struct)-2 do ixPfaf = create_struct(ixPfaf, 'pfaf00'+string(ix, format='(i2.2)'), struct.(ix))
                                  
                                   ; area is not sufficient
                                   endif else begin
                                    aggregateReaches, ixPfaf.(ixCount)[ixSubset], pCode, downSegId_mizu, endLat, endLon, pfafId
                                    ;print, pCode, total(basArea_mizu[ixPfaf.(ixCount)[ixSubset]]), pfafVec_string[ixPfaf.(ixCount)[ixSubset]]
                                   endelse
                                  
                                  endif  ; if valid
                                  ; *****
                                  ; *****

                                 endfor  ; looping through pfaf level 12
                               
                                 ; correct minimum areas
                                 ixValid = where(agArea[ixCount,*] ge 0.d, nValid)
                                 if(nValid gt 0)then begin
                                  if(min(agArea[ixCount,ixValid]) lt areaMin and total(agArea[ixCount,ixValid]) lt areaBig)then begin
                                   aggregateReaches, ixPfaf.(ixCount), pCodeOld, downSegId_mizu, endLat, endLon, pfafId
                                  endif
                                 endif
          
                                 ; decrement pCode and iCount
                                 agArea[ixCount,*] = -9999.d
                                 pCodeOld = strmid(pCodeOld,0,strlen(pCodeOld)-1)
                                 ixCount  = ixCount-1
                               
                                 ; remove element from the structure
                                 struct = ixPfaf  ; a copy of the structure
                                 ixPfaf = create_struct('pfaf00', struct.(0))                
                                 for ix=1,n_tags(struct)-2 do ixPfaf = create_struct(ixPfaf, 'pfaf00'+string(ix, format='(i2.2)'), struct.(ix))
                               
                                ; area is not sufficient
                                endif else begin
                                 aggregateReaches, ixPfaf.(ixCount)[ixSubset], pCode, downSegId_mizu, endLat, endLon, pfafId
                                 ;print, pCode, total(basArea_mizu[ixPfaf.(ixCount)[ixSubset]]), pfafVec_string[ixPfaf.(ixCount)[ixSubset]]
                                endelse
                               
                               endif  ; if valid
                               ; *****
                               ; *****

                              endfor  ; looping through pfaf level 11
                            
                              ; correct minimum areas
                              ixValid = where(agArea[ixCount,*] ge 0.d, nValid)
                              if(nValid gt 0)then begin
                               if(min(agArea[ixCount,ixValid]) lt areaMin and total(agArea[ixCount,ixValid]) lt areaBig)then begin
                                aggregateReaches, ixPfaf.(ixCount), pCodeOld, downSegId_mizu, endLat, endLon, pfafId
                               endif
                              endif
          
                              ; decrement pCode and iCount
                              agArea[ixCount,*] = -9999.d
                              pCodeOld = strmid(pCodeOld,0,strlen(pCodeOld)-1)
                              ixCount  = ixCount-1
                            
                              ; remove element from the structure
                              struct = ixPfaf  ; a copy of the structure
                              ixPfaf = create_struct('pfaf00', struct.(0))                
                              for ix=1,n_tags(struct)-2 do ixPfaf = create_struct(ixPfaf, 'pfaf00'+string(ix, format='(i2.2)'), struct.(ix))
                            
                             ; area is not sufficient
                             endif else begin
                              aggregateReaches, ixPfaf.(ixCount)[ixSubset], pCode, downSegId_mizu, endLat, endLon, pfafId
                              ;print, pCode, total(basArea_mizu[ixPfaf.(ixCount)[ixSubset]]), pfafVec_string[ixPfaf.(ixCount)[ixSubset]]
                             endelse
                            
                            endif  ; if valid
                            ; *****
                            ; *****

                           endfor  ; looping through pfaf level 10
                         
                           ; correct minimum areas
                           ixValid = where(agArea[ixCount,*] ge 0.d, nValid)
                           if(nValid gt 0)then begin
                            if(min(agArea[ixCount,ixValid]) lt areaMin and total(agArea[ixCount,ixValid]) lt areaBig)then begin
                             aggregateReaches, ixPfaf.(ixCount), pCodeOld, downSegId_mizu, endLat, endLon, pfafId
                            endif
                           endif
          
                           ; decrement pCode and iCount
                           agArea[ixCount,*] = -9999.d
                           pCodeOld = strmid(pCodeOld,0,strlen(pCodeOld)-1)
                           ixCount  = ixCount-1
                         
                           ; remove element from the structure
                           struct = ixPfaf  ; a copy of the structure
                           ixPfaf = create_struct('pfaf00', struct.(0))                
                           for ix=1,n_tags(struct)-2 do ixPfaf = create_struct(ixPfaf, 'pfaf00'+string(ix, format='(i2.2)'), struct.(ix))
                         
                          ; area is not sufficient
                          endif else begin
                           aggregateReaches, ixPfaf.(ixCount)[ixSubset], pCode, downSegId_mizu, endLat, endLon, pfafId
                           ;print, pCode, total(basArea_mizu[ixPfaf.(ixCount)[ixSubset]]), pfafVec_string[ixPfaf.(ixCount)[ixSubset]]
                          endelse
                         
                         endif  ; if valid
                         ; *****
                         ; *****

                        endfor  ; looping through pfaf level 9
                      
                        ; correct minimum areas
                        ixValid = where(agArea[ixCount,*] ge 0.d, nValid)
                        if(nValid gt 0)then begin
                         if(min(agArea[ixCount,ixValid]) lt areaMin and total(agArea[ixCount,ixValid]) lt areaBig)then begin
                          aggregateReaches, ixPfaf.(ixCount), pCodeOld, downSegId_mizu, endLat, endLon, pfafId
                         endif
                        endif
          
                        ; decrement pCode and iCount
                        agArea[ixCount,*] = -9999.d
                        pCodeOld = strmid(pCodeOld,0,strlen(pCodeOld)-1)
                        ixCount  = ixCount-1
                      
                        ; remove element from the structure
                        struct = ixPfaf  ; a copy of the structure
                        ixPfaf = create_struct('pfaf00', struct.(0))                
                        for ix=1,n_tags(struct)-2 do ixPfaf = create_struct(ixPfaf, 'pfaf00'+string(ix, format='(i2.2)'), struct.(ix))
                      
                       ; area is not sufficient
                       endif else begin
                        aggregateReaches, ixPfaf.(ixCount)[ixSubset], pCode, downSegId_mizu, endLat, endLon, pfafId
                        ;print, pCode, total(basArea_mizu[ixPfaf.(ixCount)[ixSubset]]), pfafVec_string[ixPfaf.(ixCount)[ixSubset]]
                       endelse
                      
                      endif  ; if valid
                      ; *****
                      ; *****

                     endfor  ; looping through pfaf level 8
                   
                     ; correct minimum areas
                     ixValid = where(agArea[ixCount,*] ge 0.d, nValid)
                     if(nValid gt 0)then begin
                      if(min(agArea[ixCount,ixValid]) lt areaMin and total(agArea[ixCount,ixValid]) lt areaBig)then begin
                       aggregateReaches, ixPfaf.(ixCount), pCodeOld, downSegId_mizu, endLat, endLon, pfafId
                      endif
                     endif
          
                     ; decrement pCode and iCount
                     agArea[ixCount,*] = -9999.d
                     pCodeOld = strmid(pCodeOld,0,strlen(pCodeOld)-1)
                     ixCount  = ixCount-1
                   
                     ; remove element from the structure
                     struct = ixPfaf  ; a copy of the structure
                     ixPfaf = create_struct('pfaf00', struct.(0))                
                     for ix=1,n_tags(struct)-2 do ixPfaf = create_struct(ixPfaf, 'pfaf00'+string(ix, format='(i2.2)'), struct.(ix))
                   
                    ; area is not sufficient
                    endif else begin
                     aggregateReaches, ixPfaf.(ixCount)[ixSubset], pCode, downSegId_mizu, endLat, endLon, pfafId
                     ;print, pCode, total(basArea_mizu[ixPfaf.(ixCount)[ixSubset]]), pfafVec_string[ixPfaf.(ixCount)[ixSubset]]
                    endelse
                   
                   endif  ; if valid
                   ; *****
                   ; *****

                  endfor  ; looping through pfaf level 7
                
                  ; correct minimum areas
                  ixValid = where(agArea[ixCount,*] ge 0.d, nValid)
                  if(nValid gt 0)then begin
                   if(min(agArea[ixCount,ixValid]) lt areaMin and total(agArea[ixCount,ixValid]) lt areaBig)then begin
                    aggregateReaches, ixPfaf.(ixCount), pCodeOld, downSegId_mizu, endLat, endLon, pfafId
                   endif
                  endif
          
                  ; decrement pCode and iCount
                  agArea[ixCount,*] = -9999.d
                  pCodeOld = strmid(pCodeOld,0,strlen(pCodeOld)-1)
                  ixCount  = ixCount-1
                
                  ; remove element from the structure
                  struct = ixPfaf  ; a copy of the structure
                  ixPfaf = create_struct('pfaf00', struct.(0))                
                  for ix=1,n_tags(struct)-2 do ixPfaf = create_struct(ixPfaf, 'pfaf00'+string(ix, format='(i2.2)'), struct.(ix))
                
                 ; area is not sufficient
                 endif else begin
                  aggregateReaches, ixPfaf.(ixCount)[ixSubset], pCode, downSegId_mizu, endLat, endLon, pfafId
                  ;print, pCode, total(basArea_mizu[ixPfaf.(ixCount)[ixSubset]]), pfafVec_string[ixPfaf.(ixCount)[ixSubset]]
                 endelse
                
                endif  ; if valid
                ; *****
                ; *****

               endfor  ; looping through pfaf level 6
             
               ; correct minimum areas
               ixValid = where(agArea[ixCount,*] ge 0.d, nValid)
               if(nValid gt 0)then begin
                if(min(agArea[ixCount,ixValid]) lt areaMin and total(agArea[ixCount,ixValid]) lt areaBig)then begin
                 aggregateReaches, ixPfaf.(ixCount), pCodeOld, downSegId_mizu, endLat, endLon, pfafId
                endif
               endif
          
               ; decrement pCode and iCount
               agArea[ixCount,*] = -9999.d
               pCodeOld = strmid(pCodeOld,0,strlen(pCodeOld)-1)
               ixCount  = ixCount-1
             
               ; remove element from the structure
               struct = ixPfaf  ; a copy of the structure
               ixPfaf = create_struct('pfaf00', struct.(0))                
               for ix=1,n_tags(struct)-2 do ixPfaf = create_struct(ixPfaf, 'pfaf00'+string(ix, format='(i2.2)'), struct.(ix))
             
              ; area is not sufficient
              endif else begin
               aggregateReaches, ixPfaf.(ixCount)[ixSubset], pCode, downSegId_mizu, endLat, endLon, pfafId
               ;print, pCode, total(basArea_mizu[ixPfaf.(ixCount)[ixSubset]]), pfafVec_string[ixPfaf.(ixCount)[ixSubset]]
               ;print, 'else: agArea = ' & print, agArea[0:ixCount,*]/areaConv
               ;stop
              endelse
             
             endif  ; if valid
             ; *****
             ; *****

            endfor  ; looping through pfaf level 5

            ; correct minimum areas
            ixValid = where(agArea[ixCount,*] ge 0.d, nValid)
            if(nValid gt 0)then begin
             if(min(agArea[ixCount,ixValid]) lt areaMin and total(agArea[ixCount,ixValid]) lt areaBig)then begin
              aggregateReaches, ixPfaf.(ixCount), pCodeOld, downSegId_mizu, endLat, endLon, pfafId
              ;print, 'min: ', pCodeOld, ixPfaf.(ixCount)
             endif
            endif
            tempId = pfafId[where(pfafId gt 0)]
            uniqId = tempId[uniq(tempId, sort(tempId))]
            ;print, 'hello 2'
            ;print, 'uniqId = ', uniqId
            ;print, 'agArea = ' & print, agArea[0:ixCount,*]/areaConv
            ;stop
          
            ; decrement pCode and iCount
            agArea[ixCount,*] = -9999.d
            pCodeOld = strmid(pCodeOld,0,strlen(pCodeOld)-1)
            ixCount  = ixCount-1
          
            ; remove element from the structure
            struct = ixPfaf  ; a copy of the structure
            ixPfaf = create_struct('pfaf00', struct.(0))                
            for ix=1,n_tags(struct)-2 do ixPfaf = create_struct(ixPfaf, 'pfaf00'+string(ix, format='(i2.2)'), struct.(ix))
          
           ; area is not sufficient
           endif else begin
            aggregateReaches, ixPfaf.(ixCount)[ixSubset], pCode, downSegId_mizu, endLat, endLon, pfafId
            tempId = pfafId[where(pfafId gt 0)]
            uniqId = tempId[uniq(tempId, sort(tempId))]
            ;print, 'hello 2'
            ;print, 'uniqId = ', uniqId
            ;print, 'agArea = ' & print, agArea[0:ixCount,*]/areaConv
            ;print, pCode, total(basArea_mizu[ixPfaf.(ixCount)[ixSubset]]), pfafVec_string[ixPfaf.(ixCount)[ixSubset]]
            ;stop
           endelse
          
          endif  ; if valid
          ; *****
          ; *****

         endfor  ; looping through pfaf level 4
       
         ; correct minimum areas
         ixValid = where(agArea[ixCount,*] ge 0.d, nValid)
         if(nValid gt 0)then begin
          if(min(agArea[ixCount,ixValid]) lt areaMin and total(agArea[ixCount,ixValid]) lt areaBig)then begin
           aggregateReaches, ixPfaf.(ixCount), pCodeOld, downSegId_mizu, endLat, endLon, pfafId
           ;print, 'min: ', pCodeOld, ixPfaf.(ixCount)
          endif
         endif
         tempId = pfafId[where(pfafId gt 0)]
         uniqId = tempId[uniq(tempId, sort(tempId))]
         ;print, 'hello 1'
         ;print, 'uniqId = ', uniqId
         ;print, 'agArea = ' & print, agArea[0:ixCount,*]/areaConv
         ;stop
          
         ; decrement pCode and iCount
         agArea[ixCount,*] = -9999.d
         pCodeOld = strmid(pCodeOld,0,strlen(pCodeOld)-1)
         ixCount  = ixCount-1
       
         ; remove element from the structure
         struct = ixPfaf  ; a copy of the structure
         ixPfaf = create_struct('pfaf00', struct.(0))                
         for ix=1,n_tags(struct)-2 do ixPfaf = create_struct(ixPfaf, 'pfaf00'+string(ix, format='(i2.2)'), struct.(ix))
       
        ; area is not sufficient
        endif else begin
         aggregateReaches, ixPfaf.(ixCount)[ixSubset], pCode, downSegId_mizu, endLat, endLon, pfafId
         ;print, pCode, total(basArea_mizu[ixPfaf.(ixCount)[ixSubset]]), pfafVec_string[ixPfaf.(ixCount)[ixSubset]]
         ;stop
        endelse
       
       endif  ; if valid
       ; *****
       ; *****

      endfor  ; looping through pfaf level 3
       
      ; correct minimum areas
      ixValid = where(agArea[ixCount,*] ge 0.d, nValid)
      if(nValid gt 0)then begin
       if(min(agArea[ixCount,ixValid]) lt areaMin and total(agArea[ixCount,ixValid]) lt areaBig)then begin
        aggregateReaches, ixPfaf.(ixCount), pCodeOld, downSegId_mizu, endLat, endLon, pfafId
       endif
      endif
      tempId = pfafId[where(pfafId gt 0)]
      uniqId = tempId[uniq(tempId, sort(tempId))]
      ;print, 'hello 0'
      ;print, 'uniqId = ', uniqId
      ;print, 'agArea = ' & print, agArea[0:ixCount,*]/areaConv
      ;stop
 
      ; decrement pCode and iCount
      agArea[ixCount,*] = -9999.d
      pCodeOld = strmid(pCodeOld,0,strlen(pCodeOld)-1)
      ixCount  = ixCount-1
    
      ; remove element from the structure
      struct = ixPfaf  ; a copy of the structure
      ixPfaf = create_struct('pfaf00', struct.(0))                
      for ix=1,n_tags(struct)-2 do ixPfaf = create_struct(ixPfaf, 'pfaf00'+string(ix, format='(i2.2)'), struct.(ix))
    
     ; area is not sufficient
     endif else begin
      aggregateReaches, ixPfaf.(ixCount)[ixSubset], pCode, downSegId_mizu, endLat, endLon, pfafId
      ;print, pCode, total(basArea_mizu[ixPfaf.(ixCount)[ixSubset]]), pfafVec_string[ixPfaf.(ixCount)[ixSubset]]
      ;stop
     endelse
    
    endif  ; if valid
    ; *****
    ; *****

   endfor  ; looping through pfaf level 2
 
   ; correct minimum areas
   ixValid = where(agArea[ixCount,*] ge 0.d, nValid)
   if(nValid gt 0)then begin
    if(min(agArea[ixCount,ixValid]) lt areaMin and total(agArea[ixCount,ixValid]) lt areaBig)then begin
     aggregateReaches, ixPfaf.(ixCount), pCodeOld, downSegId_mizu, endLat, endLon, pfafId
    endif
   endif
          
   ; decrement pCode and iCount
   agArea[ixCount,*] = -9999.d
   pCodeOld = strmid(pCodeOld,0,strlen(pCodeOld)-1)
   ixCount  = ixCount-1
 
   ; remove element from the structure
   struct = ixPfaf  ; a copy of the structure
   ixPfaf = create_struct('pfaf00', struct.(0))                
   for ix=1,n_tags(struct)-2 do ixPfaf = create_struct(ixPfaf, 'pfaf00'+string(ix, format='(i2.2)'), struct.(ix))
 
  ; area is not sufficient
  endif else begin
   aggregateReaches, ixPfaf.(ixCount)[ixSubset], pCode, downSegId_mizu, endLat, endLon, pfafId
   ;print, pCode, total(basArea_mizu[ixPfaf.(ixCount)[ixSubset]]), pfafVec_string[ixPfaf.(ixCount)[ixSubset]]
  endelse
 
 endif  ; if valid
 ; *****
 ; *****

endfor  ; looping through pfaf level 1 

end
