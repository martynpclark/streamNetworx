pro define_aggregate, pfafCode, pCode_flowline, downSegIndex_mizu, ixSubset, iyMapping, izMapping, idAggregate, numAggregate

; get pfaf old and pfaf new
pfaf_old = long(strmid(pfafCode,strlen(pfafCode)-2,1))
pfaf_new = long(strmid(pfafCode,strlen(pfafCode)-1,1))

; check if an interbasin
isInterbasin = ( (pfaf_new mod 2) eq 1)
isHeadwater  = ( (pfaf_old mod 2) eq 0 and pfaf_new eq 9)
if(isInterbasin eq 1 and isHeadwater eq 0)then begin

 ; get the valid river network
 ixNetwork = where(downSegIndex_mizu[ixSubset] gt 0, nNetwork)
 iyNetwork = ixSubset[ixNetwork]

 ; restrict attention to valid network
 iyMapping[iyNetwork] = long(pfafCode)
 okMapping = iyMapping[downSegIndex_mizu[iyNetwork]-1]
 ixValid   = where(okMapping eq long(pfafCode), nValid)
 izNetwork = iyNetwork[ixValid]

 ; get the main stem
 get_mainStem, pfafCode, pCode_flowline[izNetwork], isMainStem
 ixMainstem = where(isMainStem eq 1, nMainstem)
 iyMainstem = izNetwork[ixMainstem]
 idAggregate[iyMainstem]  = -long(pfafCode)
 numAggregate[iyMainstem] = nMainstem
 print, 'nMainstem = ', nMainstem

 ; identify the tributaries
 izMapping[izNetwork] = isMainStem
 ixTrib = where(izMapping[downSegIndex_mizu[izNetwork]-1] eq 1 and izMapping[izNetwork] eq 0, nTrib)
 iyTrib = izNetwork[ixTrib]
 print, 'nTrib = ', nTrib

 ; loop through the tributaries
 for iTrib=0,nTrib-1 do begin

  ; get the matching pfafstetter codes
  pfafTrib = pCode_flowline[iyTrib[iTrib]]
  cSuffix  = strmid(pfafTrib, strlen(pfafCode))
  for i=strlen(cSuffix)-1,0,-1 do if((long(strmid(cSuffix,i,1)) mod 2) eq 0)then j=i
  pfafBase = pfafCode+strmid(cSuffix,0,j+1) 
  ixMatch  = where(strmid(pCode_flowline[izNetwork],0,strlen(pfafBase)) eq pfafBase, nMatch)
  iyMatch  = izNetwork[ixMatch]
  
  ; save the matching codes
  idAggregate[iyMatch]  = long(pfafBase)
  numAggregate[iyMatch] = nMatch

 endfor  ; looping through the tributaries

; trib
endif else begin
 idAggregate[ixSubset]  = long(pfafCode)
 numAggregate[ixSubset] = n_elements(ixSubset)
endelse

end
