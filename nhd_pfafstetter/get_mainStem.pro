pro get_mainStem, idUnique, codeVec, isMainStem

; initialize output
nStream    = n_elements(codeVec)
isMainStem = replicate(0, nStream) 

; get the length of the unique ID
uniqLen    = strlen(idUnique)

; loop through streams
for iStream=0,nStream-1 do begin

 ; simple case of one stream segment
 if(nStream eq 1)then begin
  isMainstem[iStream] = 1

 ; standard case: find odd-numbered segments
 endif else begin
  ; disaggregate pfafsttter code ** REMAINDER** into a vector of digits
  sLength = strlen(codeVec[iStream]) - uniqLen
  strVec  = strarr(sLength)
  reads, strmid(codeVec[iStream], uniqLen), strVec, format='(20(a1))'
  ; check if all of the remainder is odd
  if(total(byte(strVec) mod 2, /integer) eq sLength)then isMainstem[iStream] = 1
 endelse

endfor  ; looping through streams

end
