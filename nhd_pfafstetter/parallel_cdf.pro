pro parallel_cdf

; define shapefile
shpPath  = '/Volumes/d1/mclark/NHD_Plus/ancillary_data/nhdPlus_SHPs_aggregate/'
shpFiles = ['Flowline_CO_14-parallel.shp']

; loop through files
for ifile=0,n_elements(shpFiles)-1 do begin

 ; define shapefile
 shpFile = shpPath + shpFiles[iFile]

 ; get the attributes
 print, shpFile[ifile]
 get_attributes, shpFile, 'idFeature',  idFeature
 get_attributes, shpFile, 'nAggregate', nAggregate

 ; identify tributaries
 ixTrib = where(idFeature gt 0, nTrib, ncomplement=nMainStem)
 upTrib = long(idFeature[ixTrib])
 numUps = long(nAggregate[ixTrib])

 ; get unique trib ids
 sortTrib = sort(upTrib)
 ixUnique = uniq(upTrib, sortTrib)
 nUnique  = n_elements(ixUnique)
 print, 'nUnique trib = ', nUnique

 ; sort by the number of tribs
 ixSort = reverse(sort(numUps[ixUnique]))

 ; get tributary arrays
 numTrib = lonarr(nUnique)
 
 jTrib = 0
 ; identify the number of segments in each unique 
 for iUnique=0,nUnique-1 do begin
  iTrib  = ixUnique[ixSort[iUnique]]
  idTrib = upTrib[iTrib]
  numTrib[jTrib] = numUps[iTrib]
  print, idTrib, numTrib[jTrib]
  jTrib = jTrib+1
 endfor

 ; define the number of processors
 nProc = 10

 ; define the even load across nTrib+1 processors 
 nEven = long(total(numTrib) / double(nProc+1))

 ; define segments reserved for the "main stem" processor
 nAgg=0
 nReserved=0
 for iUnique=nUnique-1,0,-1 do begin
  nAgg = nAgg + numTrib[iUnique]
  nReserved = nReserved+1
  if(iUnique mod 100)then print, iUnique, numTrib[iUnique], nAgg
  if(nAgg gt nEven)then break
 endfor

 ; get the number of tributaries distributed
 nDistrib  = nUnique - nReserved

 ; intitialize processor
 iTrib = 0
 iWork = replicate(0L, nProc)
 nComm = replicate(0L, nProc)

 ; loop through tributaries
 while (iTrib lt nDistrib) do begin

  ; loop forwards, then backwards
  for iProc=0,nProc-1 do begin
   ; get the processor with the smallest number of segments
   xMin = min(iWork, jProc)
   ; put the data on the jProc processor
   iWork[jProc] = iWork[jProc] + numTrib[iTrib]
   nComm[jProc] = nComm[jProc]+1
   iTrib = iTrib+1
   if(iTrib eq nUnique)then break
  endfor
 
 endwhile ; looping through tributaries

 print, 'nMainStem = ', nMainstem, format='(a12,1x,i5)'
 print, 'iWork = ', iWork, format='(a12,1x,10(i4,1x))'
 print, 'nComm = ', nComm, format='(a12,1x,10(i4,1x))'

 stop


endfor ; looping through files


stop
end
