pro aggregatePfaf

; Used to aggregate NHD+ catchments 

; get path to NHD-plus
nhd_root = '/Users/mac414/geospatial_data/NHD_Plus/ancillary_data/'

; define NetCDF files
ncfile_old = nhd_root + 'conusPfafstetter.nc'
ncfile_new = nhd_root + 'conusPfafstetter_aggregate.nc'

; define path for .sav files
savePath = nhd_root + 'idlSave/'

; *****
; * READ THE NHD+ TOPOLOGY...
; ***************************

; define the NetCDF file
nc_filename = nhd_root + 'NHDPlus2_updated-CONUS.nc'
print, 'Reading ancillary file'

; open file
nc_file = ncdf_open(nc_filename, /nowrite)

 ; get the downstream segid
 ivar_id = ncdf_varid(nc_file,'idFeature')
 ncdf_varget, nc_file, ivar_id, hruId_mizu

 ; get the segid
 ivar_id = ncdf_varid(nc_file,'link')
 ncdf_varget, nc_file, ivar_id, segId_mizu

 ; get the number of immediate upstream reaches
 ivar_id = ncdf_varid(nc_file,'upSeg_count')
 ncdf_varget, nc_file, ivar_id, nUpstream_mizu

 ; get the downstream segid
 ivar_id = ncdf_varid(nc_file,'to')
 ncdf_varget, nc_file, ivar_id, downSegId_mizu

 ; get the local basin area
 ivar_id = ncdf_varid(nc_file,'basArea')
 ncdf_varget, nc_file, ivar_id, basArea_mizu

 ; get the total upstream area
 ivar_id = ncdf_varid(nc_file,'totalArea')
 ncdf_varget, nc_file, ivar_id, totalArea_mizu

; close file
ncdf_close, nc_file

; get the number of stream segments
nHRU = n_elements(hruId_mizu)
nSeg = n_elements(segId_mizu)

; *****
; * READ THE PFAFSTETTER CODES...
; *******************************

print, 'Reading the Pfafstetter code'

; read the pfafstetter code
ncid = ncdf_open(ncfile_old, /nowrite)
 
 ; index variables
 ncdf_varget, ncid, ncdf_varid(ncid, 'hruId'), comId_hru
 ncdf_varget, ncid, ncdf_varid(ncid, 'segId'), comId_seg

 ; pfafstetter codes
 ncdf_varget, ncid, ncdf_varid(ncid, 'pfafCode_hru'), pfafCode_hru
 ncdf_varget, ncid, ncdf_varid(ncid, 'pfafCode_seg'), pfafCode_seg

; close netcdf file
ncdf_close, ncid

; check that no catchment values are negative
ixNegative = where(strmid(strtrim(pfafCode_hru,2),0,1) eq '-', nNegative)
if(nNegative gt 0)then begin
 print, nNegative
 print, pfafCode_hru[ixNegative]
 stop, 'some catchment Pfafstetter codes are negative'
endif

; check that no stream segment values are negative
ixNegative = where(strmid(strtrim(pfafCode_seg,2),0,1) eq '-', nNegative)
if(nNegative gt 0)then begin
 print, nNegative
 print, pfafCode_seg[ixNegative]
 stop, 'some stream segment Pfafstetter codes are negative'
endif

; re-order the Pfafstetter codes for the catchments
pfafVec_hru = strarr(nHRU)
pfafVec_hru[sort(hruId_mizu)] = strtrim(pfafCode_hru[sort(comId_hru)], 2)

; re-order the Pfafstetter codes for the stream segments
pfafVec_string = strarr(nSeg)
pfafVec_string[sort(segId_mizu)] = strtrim(pfafCode_seg[sort(comId_seg)], 2)

; check that no values are zero where the upstream area is non-zero
areaTol = 1.d-8
ixZero  = where(strmid(strtrim(pfafVec_string,2),0,1) eq '0', nZero)
if(nZero gt 0)then begin
 ixMatch = where(totalArea_mizu[ixZero] gt areaTol, nMatch)
 if(nMatch gt 0)then stop, strtrim(nZero,2)+' Pfafstetter codes are zero for reaches where upstream area is greater than '+strtrim(areaTol,2)
endif

; get the Pfafstetter code as a very long integer
pfafVec = long64(pfafVec_string)

; *****
; * GET THE LOCATION OF THE DANGLING REACHES...
; *********************************************

; get the latutude and longitude of the end point
endLat = dblarr(nSeg)
endLon = dblarr(nSeg)

; get the location of the dangling reaches
saveFile = savePath + 'locationDangle.sav'
if(file_test(saveFile) eq 0)then begin
 locationDangle, segId_mizu, downSegId_mizu, endLat, endLon
 save, endLat, endLon, filename=saveFile
endif else begin
 restore, saveFile
endelse

; =======================================================================================================
; =======================================================================================================
; =======================================================================================================
; =======================================================================================================
; =======================================================================================================
; =======================================================================================================
; =======================================================================================================

; define the Pfafstetter code
pfafId   = replicate(0LL, nSeg)
classHRU = replicate(0LL, nHRU)

; define area threahold
areaConv = 1.d+6              ; area conversion factor (km2-->m2)
areaMin  =  10.d * areaConv   ; minimum area  50 km2
areaMax  = 250.d * areaConv   ; maximum area 250 km2

; define save file
saveFile = savePath + 'aggregate_conus.sav'
;spawn, 'rm -f '+saveFile

; check if the save file does not exist
if(file_test(saveFile) eq 0)then begin

 ; *****
 ; * AGGREGATE THE PFAFSTETTER CODES...
 ; ************************************

 ; loop through regions
 for iRegion=1,9 do begin

  ; get the base pfafstetter code
  basePfaf = strtrim(iRegion,2)

  ; get intial indices
  ixInitial = where(strmid(strtrim(pfafVec_string,2),0,strlen(basePfaf)) eq basePfaf, nInitial)
  if(nInitial eq 0)then continue

  ; get the non-unique indices defining stream segment aggregation
  getAggregationIndices, basePfaf, ixInitial, pfafVec_string, basArea_mizu, downSegId_mizu, endLat, endLon, areaMin, areaMax, pfafId

  ; get the unique indices for the stream segments
  classVec = pfafId[ixInitial]
  uniqVec  = classVec[uniq(classVec, sort(classVec))]

  ; get intial indices
  iyInitial = where(strmid(strtrim(pfafVec_hru,2),0,strlen(basePfaf)) eq basePfaf, nInitial)
  if(nInitial eq 0)then stop, 'expect valid hrus'

  ; get sub-strings
  subUniq = strmid(strtrim(uniqVec,2),0,3)
  subPfaf = strmid(strtrim(pfafVec_hru[iyInitial],2),0,3)

  ; loop through Pfafstetter subsets (save computational time)
  for iPfaf1=0,9 do begin
   for iPfaf2=0,9 do begin
    pCode = strtrim(iRegion,2) + strtrim(iPfaf1,2) + strtrim(iPfaf2,2)

    ; get the subset of the unique string
    ixUniq = where(subUniq eq pCode, nUniq)
    if(nUniq eq 0)then continue

    ; get the subset of the hru pfafstetter code
    ixPfaf = where(subPfaf eq pCode, nPfaf)
    if(nPfaf eq 0)then continue 

    ; loop through unique strings
    for iUniq=0,nUniq-1 do begin
     if(uniqVec[ixUniq[iUniq]] eq 0)then continue

     ; get the matching indices
     cUnique  = strtrim(uniqVec[ixUniq[iUniq]],2)
     pfafTrim = strmid(pfafVec_hru[iyInitial[ixPfaf]],0,strlen(cUnique))
     ixMatch  = where(pfafTrim eq cUnique, nMatch)
     if(nMatch eq 0)then continue 

     ; aggregate HRUs
     classHRU[iyInitial[ixPfaf[ixMatch]]] = uniqVec[ixUniq[iUniq]]
     if(iUniq mod 100 eq 0)then print, 'aggregating HRUs: ', pCode, iUniq, nUniq, nMatch

    endfor  ; loop through unique classes

   endfor  ; looping through pfaf2
  endfor  ; looping through pfaf1

 endfor  ; looping through regions

 ; save pfafId
 save, pfafId, classHRU, filename=saveFile

 ; *****
 ; * WRITE TO THE NETCDF FILE...
 ; *****************************

 ; define the NetCDF file
 spawn, 'rm ' + ncfile_new
 
 ; create file
 if(file_test(ncfile_new) eq 0)then begin
  print, 'Creating the NetCDF file for the Pfafstetter code'
  spawn, 'cp -f ' + ncfile_old + ' ' + ncfile_new
  ncid = ncdf_open(ncfile_new, /write)
  ncdf_control, ncid, /redef
 
   ; hru classification
   dimId = ncdf_dimid(ncid, 'hru')
   varid = ncdf_vardef(ncid, 'pfafClass_hru', [dimid], /string)
 
   ; seg classification
   dimId = ncdf_dimid(ncid, 'seg')
   varid = ncdf_vardef(ncid, 'pfafClass_seg', [dimid], /string)
 
  ; end file definitions
  ncdf_control, ncid, /endef
  ncdf_close, ncid
 endif  ; if creating file

 ; open file 
 ncid  = ncdf_open(ncfile_new, /write)

 print, 'Writing the hru id'
 varid = ncdf_varid(ncid, 'hruId')
 ncdf_varput, ncid, varid, hruId_mizu              ; note: Pfaf classification sorted to match hruId_mizu

 print, 'Writing the seg id'
 varid = ncdf_varid(ncid, 'segId')
 ncdf_varput, ncid, varid, segId_mizu              ; note: Pfaf classification sorted to match segId_mizu

 print, 'Writing the catchment Pfafstetter codes'
 varid = ncdf_varid(ncid, 'pfafCode_hru')
 ncdf_varput, ncid, varid, string(pfafVec_hru)     ; note: Pfaf classification sorted to match hruId_mizu

 print, 'Writing the segment Pfafstetter codes'
 varid = ncdf_varid(ncid, 'pfafCode_seg')
 ncdf_varput, ncid, varid, string(pfafVec_string)  ; note: Pfaf classification sorted to match segId_mizu

 print, 'Writing the catchment Pfafstetter classification'
 varid = ncdf_varid(ncid, 'pfafClass_hru')         ; note: Pfaf classification sorted to match hruId_mizu
 ncdf_varput, ncid, varid, string(classHRU)

 print, 'Writing the segment Pfafstetter classification'
 varid = ncdf_varid(ncid, 'pfafClass_seg')         ; note: Pfaf classification sorted to match segId_mizu
 ncdf_varput, ncid, varid, string(pfafId)

 ; close file
 ncdf_close, ncid

; restore pfafId
endif else begin
 restore, saveFile
endelse

; *****
; * GET THE AREA FOR UNIQUE BASINS...
; ***********************************

; get the subset
ixConus = where(pfafId gt 0LL, nConus)
if(nConus eq 0)then stop, 'nothing in the conus'
print, 'nConus = ', nConus

; get the unique basin codes
pfafSubset = pfafId[ixConus]
uniqSubset = pfafSubset[uniq(pfafSubset, sort(pfafSubset))]
nUnique    = n_elements(uniqSubset)

; get the first three digits of the string
pfafString = strmid(strtrim(pfafSubset,2),0,3)
uniqString = strmid(strtrim(uniqSubset,2),0,3)

; get the aggregated area
aggArea = replicate(-9999.d, nUnique)
for iRegion=1,9 do begin
 for iPfaf1=0,9 do begin
  for iPfaf2=0,9 do begin
  
   ; get subsets (reduce computational time for searching)
   pCode  = strtrim(iRegion,2) + strtrim(iPfaf1,2) + strtrim(iPfaf2,2)
   ixPfaf = where(pfafString eq pCode, nPfaf)
   ixUniq = where(uniqString eq pCode, nUniq)
  
   ; check we have a unique match
   if(nUniq gt 0)then begin
  
    ; loop through unique strings for the subset
    for iUniq=0,nUniq-1 do begin
  
     ; get the match
     ixMatch = where(pfafSubset[ixPfaf] eq uniqSubset[ixUniq[iUniq]], nMatch)
     if(nMatch eq 0)then stop, 'expect at least one match with the unique code'
    
     ; save the area
     aggArea[ixUniq[iUniq]] = total(basArea_mizu[ixConus[ixPfaf[ixMatch]]]) / areaConv
     if(iUniq eq 0)then print, pCode+': ', aggArea[ixUniq[iUniq]]
    
    endfor  ; looping through unique ids 
  
   endif  ; if data exists in the subset
  
  endfor  ; ipfaf2
 endfor  ; ipfaf1
endfor  ; region

; *****
; * READ THE HUC-12 DATA...
; *************************

; Define shapefile
huc12_filepath = '/Users/mac414/geospatial_data/HUC/conus/'
shp_huc12     = huc12_filepath + 'huc12.shp'

; get the desired attributes
get_attributes, shp_huc12, 'AreaSqKm', basinArea

; get the number of basins
nBasins  = n_elements(basinArea)

; *****
; * PLOT THE HUC-12 DATA...
; *************************

; define plotting parameters
window, 0, xs=700, ys=700, retain=2;, /pixmap
device, decomposed=0

; set defaults
loadct, 39
!P.COLOR=1
!P.BACKGROUND=255
!P.CHARSIZE=2.5
!P.MULTI=1
erase, color=255

; make a base plot
plot, indgen(5), xrange=[0,500], yRange=[0,1], xstyle=1, ystyle=1, $
 xtitle='basin Area (km!e2!n)', ytitle='Cumulative probability', $
 title='HUC-12 Area', /nodata

; sort the basin area
ixSort = sort(basinArea)

; get the cumulative probability
cProb = (dindgen(nBasins)+1.d) / double(nBasins)

; plot
oplot, basinArea[ixSort], cProb, color=250, thick=2

; plot the aggregated information
ixSort = sort(aggArea)
cProb  = (dindgen(nUnique)+1.d) / double(nUnique)
oplot, aggArea[ixSort], cProb, color=80, thick=2

; plot the raw information
ixSort = sort(basArea_mizu[ixConus])
cProb  = (dindgen(nConus)+1.d) / double(nConus)
oplot, basArea_mizu[ixConus[ixSort]]/areaConv, cProb, color=120, thick=2

; plot the number of unique bins
xyouts, 490, 0.05, 'nUnique = '+strtrim(nUnique,2), alignment=1

; save figure
figure_filename = 'conus_basArea.png'
write_png, figure_filename, tvrd(true=1)

print, 'nUnique = ', nUnique

stop
end
