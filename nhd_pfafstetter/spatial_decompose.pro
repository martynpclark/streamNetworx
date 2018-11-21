pro spatial_decompose

; *****
; * DEFINE SHAPEFILES...
; **********************

; define entity types
typeCatch  = 5 ; entityType=5 is a polygon
typeStream = 3 ; entityType=3 is a polyLine

; define path for .sav files
savePath = '/Volumes/d1/mclark/NHD_Plus/ancillary_data/idlSave/'

; get path to shapefile
shp_root = '/Volumes/d1/mclark/NHD_Plus/ancillary_data/'
shp_path = shp_root + 'nhdPlus_SHPs_class/'

; Define shapefiles
nhdFiles = [$
            ['CO','14' ], $
            ['SA','03N'], $
            ['MS','10U'], $
            ['PN','17' ], $
            ['GB','16' ], $
            ['SR','09' ], $
            ['CA','18' ], $
            ['NE','01' ], $
            ['MA','02' ], $
            ['SA','03W'], $
            ['SA','03S'], $
            ['GL','04' ], $
            ['MS','05' ], $
            ['MS','06' ], $
            ['MS','07' ], $
            ['MS','08' ], $
            ['MS','10L'], $
            ['MS','11' ], $
            ['TX','12' ], $
            ['RG','13' ], $
            ['CO','15' ], $
            ['MA','02' ]  ]

; *****
; * READ THE NHD+ TOPOLOGY...
; ***************************

; define the NetCDF file
nc_filepath = '/Volumes/d1/mclark/NHD_Plus/ancillary_data/'
nc_filename = nc_filepath + 'NHDPlus2_updated-CONUS.nc'
print, 'Reading ancillary file'

; open file
nc_file = ncdf_open(nc_filename, /nowrite)

 ; get the segid
 ivar_id = ncdf_varid(nc_file,'link')
 ncdf_varget, nc_file, ivar_id, segId_mizu

 ; get the downstream index
 ivar_id = ncdf_varid(nc_file,'downSegIndex')
 ncdf_varget, nc_file, ivar_id, downSegIndex_mizu

; close file
ncdf_close, nc_file

; get the number of stream segments
nSeg = n_elements(segId_mizu)

; *****
; * READ THE PFAFSTETTER CODES...
; *******************************

nc_filepath = '/Volumes/d1/mclark/NHD_Plus/ancillary_data/'
nc_filename = nc_filepath + 'conusPfafstetter_aggregate.nc'
print, 'Reading the Pfafstetter code'

; open file
ncid = ncdf_open(nc_filename, /nowrite)

; read the segment ID
varid = ncdf_varid(ncid, 'segId')
ncdf_varget, ncid, varid, segId_pfaf

; read the pfafstetter code for stream segments
varid = ncdf_varid(ncid, 'pfafCode_seg')
ncdf_varget, ncid, varid, pCode_flowline

; close file
ncdf_close, ncid

; re-order vectors for streamflow
pCode_seg  = strarr(nSeg)
pCode_seg[ sort(segId_mizu)] = strtrim(pCode_flowline[ sort(segId_pfaf)], 2)

; get mapping vectors
iyMapping = replicate(0L, nSeg)
izMapping = replicate(0L, nSeg)

; get aggregation ids
idAggregate  = lonarr(nSeg)
numAggregate = lonarr(nSeg)

; loop through shapefiles
for iFile=0,n_elements(nhdFiles)/2-1 do begin

 ; *****
 ; * READ SHAPEFILES...
 ; ********************

 ; define the original shapefile
 shpFile_orig = shp_path + 'Flowline_' + nhdFiles[0,iFile] + '_' + nhdFiles[1,iFile] + '.shp'
 print, shpFile_orig

 ; read shapefile
 get_attributes, shpFile_orig, 'COMID', segId_sh
 get_shapes, shpFile_orig, seg_shapes

 ; get the match
 matchName = savePath + 'matchShapeMizuRoute_' + 'Flowline_' + nhdFiles[0,iFile] + '_' + nhdFiles[1,iFile] + '.sav'
 ;spawn, 'rm ' + matchName
 if(file_test(matchName) eq 0)then begin
  print, 'Matching the file ', matchName
  match, segId_mizu, segID_sh, segId_mizu_ix, segID_sh_ix
  save, segId_mizu_ix, segID_sh_ix, filename=matchName
 endif else begin
  print, 'Restoring the file ', matchName
  restore, matchName
 endelse

 ; define new shapefile
 shpFile_new = shp_root + 'nhdPlus_SHPs_aggregate/' + 'Flowline_' + nhdFiles[0,iFile] + '_' + nhdFiles[1,iFile] + '-parallel.shp'

 ; define variables
 varNames = ['idFeature', 'nAggregate']
 defineShapefile, typeStream, varNames,  shpFile_new

 ; *****
 ; * LOOP THROUGH PFAFSTETTER CODES...
 ; ***********************************

 ; define threshold
 nThresh = 10000L

 ; initialize counter
 kMatch=0L

 ; intialize subset (entire region)
 ixSubset = segId_mizu_ix
 pfafCode = '96'

 ; loop through Pfafstetter codes
 for iPfaf0=1,9 do begin

  ; get the subset
  pfaf_new = iPfaf0
  pfafCode = pfafCode + strtrim(pfaf_new,2)
  ixMatch  = where(strmid(pCode_flowline[ixSubset],0,strlen(pfafCode)) eq pfafCode, nMatch)
  print, 'pfafCode = ', pfafCode, nMatch
  if(nMatch eq 0)then begin
   pfafCode = strmid(pfafCode,0,strlen(pfafCode)-1)
   continue
  endif

  ; check if we aggregate
  if(nMatch lt nThresh)then begin

   ; aggregate
   define_aggregate, pfafCode, pCode_flowline, downSegIndex_mizu, ixSubset[ixMatch], iyMapping, izMapping, idAggregate, numAggregate

   ; write shapefile
   for iMatch=0,nMatch-1 do begin
    jMatch = ixMatch[iMatch]
    lMatch = ixSubset[jMatch]
    intVec = [idAggregate[lMatch], numAggregate[lMatch]]
    aggregateShapefile, typeStream, kMatch, varNames, intVec, shpFile_new, seg_shapes, segId_sh_ix[jMatch] 
    kMatch = kMatch+1
   endfor

  endif else begin ; aggregating

   ; reset pfaf code
   pfaf_old = iPfaf0

   ; =============== NEW LEVEL ==================== 

   ; loop through Pfafstetter codes
   for iPfaf1=1,9 do begin

    ; get the subset
    pfaf_new = iPfaf1
    pfafCode = pfafCode + strtrim(pfaf_new,2)
    ixMatch  = where(strmid(pCode_flowline[ixSubset],0,strlen(pfafCode)) eq pfafCode, nMatch)
    print, 'pfafCode = ', pfafCode, nMatch
    if(nMatch eq 0)then begin
     pfafCode = strmid(pfafCode,0,strlen(pfafCode)-1)
     continue
    endif
   
    ; check if we aggregate
    if(nMatch lt nThresh)then begin
   
     ; aggregate
     define_aggregate, pfafCode, pCode_flowline, downSegIndex_mizu, ixSubset[ixMatch], iyMapping, izMapping, idAggregate, numAggregate
   
     ; write shapefile
     for iMatch=0,nMatch-1 do begin
      jMatch = ixMatch[iMatch]
      lMatch = ixSubset[jMatch]
      intVec = [idAggregate[lMatch], numAggregate[lMatch]]
      aggregateShapefile, typeStream, kMatch, varNames, intVec, shpFile_new, seg_shapes, segId_sh_ix[jMatch] 
      kMatch = kMatch+1
     endfor

    endif else begin

     ; reset pfaf code
     pfaf_old = iPfaf1

     ; =============== NEW LEVEL ====================
   
     ; loop through Pfafstetter codes
     for iPfaf2=1,9 do begin
   
      ; get the subset
      pfaf_new = iPfaf2
      pfafCode = pfafCode + strtrim(pfaf_new,2)
      ixMatch  = where(strmid(pCode_flowline[ixSubset],0,strlen(pfafCode)) eq pfafCode, nMatch)
      print, 'pfafCode = ', pfafCode, nMatch
      if(nMatch eq 0)then begin
       pfafCode = strmid(pfafCode,0,strlen(pfafCode)-1)
       continue
      endif
   
      ; check if we aggregate
      if(nMatch lt nThresh)then begin
   
       ; aggregate
       define_aggregate, pfafCode, pCode_flowline, downSegIndex_mizu, ixSubset[ixMatch], iyMapping, izMapping, idAggregate, numAggregate
   
       ; write shapefile
       for iMatch=0,nMatch-1 do begin
        jMatch = ixMatch[iMatch]
        lMatch = ixSubset[jMatch]
        intVec = [idAggregate[lMatch], numAggregate[lMatch]]
        aggregateShapefile, typeStream, kMatch, varNames, intVec, shpFile_new, seg_shapes, segId_sh_ix[jMatch] 
        kMatch = kMatch+1
       endfor
   
      endif else begin
   
       ; reset pfaf code
       pfaf_old = iPfaf2

       ; =============== NEW LEVEL ====================

       stop, 'need logic'
    
      endelse  ; diving to a deeper pfaf level

      ; decrement
      pfafCode = strmid(pfafCode,0,strlen(pfafCode)-1)

     endfor    ; pfaf

     ; --------------- END LEVEL --------------------

    endelse  ; diving to a deeper pfaf level

    ; decrement
    pfafCode = strmid(pfafCode,0,strlen(pfafCode)-1)

   endfor  ; pfaf

   ; --------------- END LEVEL --------------------

  endelse  ; diving to a deeper pfaf level

  ; decrement
  pfafCode = strmid(pfafCode,0,strlen(pfafCode)-1)
  ;stop, 'stop: level0'

 endfor  ; pfaf

 ; --------------- END LEVEL --------------------
 stop, 'completed region'

endfor  ; looping through shapefiles

stop
end
