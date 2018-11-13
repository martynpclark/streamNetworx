pro mizuRoute_aggregate

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
            ['MS','10U'], $
            ['SA','03N'], $
            ['PN','17' ], $
            ['CO','14' ], $
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

 ; get the HRU id
 ivar_id = ncdf_varid(nc_file,'idFeature')
 ncdf_varget, nc_file, ivar_id, hruId_mizu

 ; get the HRU id
 ivar_id = ncdf_varid(nc_file,'HRU_AREA')
 ncdf_varget, nc_file, ivar_id, hruArea_mizu

 ; get the stream segment that the HRU flows into
 ivar_id = ncdf_varid(nc_file,'hru2seg')
 ncdf_varget, nc_file, ivar_id, hru2seg_mizu

 ; get the index of the stream segment below each HRU
 ivar_id = ncdf_varid(nc_file,'hruSegIndex')
 ncdf_varget, nc_file, ivar_id, hruSegIndex_mizu

 ; get the segid
 ivar_id = ncdf_varid(nc_file,'link')
 ncdf_varget, nc_file, ivar_id, segId_mizu

 ; get the downstream segid
 ivar_id = ncdf_varid(nc_file,'to')
 ncdf_varget, nc_file, ivar_id, downSegId_mizu

 ; get the downstream index
 ivar_id = ncdf_varid(nc_file,'downSegIndex')
 ncdf_varget, nc_file, ivar_id, downSegIndex_mizu

 ; get the local basin area
 ivar_id = ncdf_varid(nc_file,'basArea')
 ncdf_varget, nc_file, ivar_id, basArea_mizu

 ; get the total upstream area
 ivar_id = ncdf_varid(nc_file,'totalArea')
 ncdf_varget, nc_file, ivar_id, totalArea_mizu

 ; get the stream slope
 ivar_id = ncdf_varid(nc_file,'So')
 ncdf_varget, nc_file, ivar_id, segSlope_mizu

 ; get the stream length
 ivar_id = ncdf_varid(nc_file,'Length')
 ncdf_varget, nc_file, ivar_id, segLength_mizu

; close file
ncdf_close, nc_file

; get the number of HRUs and stream segments
nHRU = n_elements(hruId_mizu)
nSeg = n_elements(segId_mizu)

; get the subset of HRUs that drain into a stream segment
ixHRU   = lindgen(nHRU)
ixValid = where(hruSegIndex_mizu ne -9999, nValid)

; define the HRU associated with each stream segment
ixSeg2hru = replicate(-9999L, nSeg)
ixSeg2hru[hruSegIndex_mizu[ixValid]-1] = ixHRU[ixValid]

; test
iStart=2423L
for iSeg=iStart,iStart+10 do begin
 if(ixSeg2hru[iSeg] ne -9999L)then print, 'test: id = ', ixSeg2hru[iSeg], segId_mizu[iSeg], hruId_mizu[ixSeg2hru[iSeg]]
endfor

; *****
; * READ THE REGRIDDING FILE...
; *****************************

; define the NetCDF file
nc_filepath = '/Volumes/d1/mclark/NHD_Plus/ancillary_data/grid2poly/'
nc_filename = nc_filepath + 'spatialweights_NLDAS12km_NHDPlus2_mod.nc'
print, 'Reading spatial weights file'

; open file
nc_file = ncdf_open(nc_filename, /nowrite)

 ; get the polygon id (NHD+) -- dimension HRU
 ivar_id = ncdf_varid(nc_file,'polyid')
 ncdf_varget, nc_file, ivar_id, hruId_remap

 ; get the number of overlapping NLDAS polygons -- dimension HRU
 ivar_id = ncdf_varid(nc_file,'overlaps')
 ncdf_varget, nc_file, ivar_id, nOverlap_remap

 ; get the weights assigned to overlapping NLDAS polygons (grid cells) -- dimension ragged
 ivar_id = ncdf_varid(nc_file,'weight')
 ncdf_varget, nc_file, ivar_id, weight_remap

 ; get the ID of the overlapping NLDAS polygons (grid cells) -- dimension ragged
 ivar_id = ncdf_varid(nc_file,'overlapPolyId')
 ncdf_varget, nc_file, ivar_id, idOverlap_remap

 ; get the i-index of the overlapping NLDAS polygons (grid cells) -- dimension ragged
 ivar_id = ncdf_varid(nc_file,'i_index')
 ncdf_varget, nc_file, ivar_id, iIndex_remap

 ; get the j-index of the overlapping NLDAS polygons (grid cells) -- dimension ragged
 ivar_id = ncdf_varid(nc_file,'j_index')
 ncdf_varget, nc_file, ivar_id, jIndex_remap

 ; get the id of the NHD+ polygons  -- dimension ragged
 ivar_id = ncdf_varid(nc_file,'IDmask')
 ncdf_varget, nc_file, ivar_id, idOrig_remap

; close file
ncdf_close, nc_file

; get the indices in the mizuRoute file
mizu2remap = replicate(-9999LL, nHRU)
mizu2remap[sort(hruId_mizu)] = sort(hruId_remap)

; check
if(max(abs(hruId_remap[mizu2remap] - hruId_mizu)) gt 0)then stop, 'cannot match remapping file'

; define remapping structure
remap=ptrarr(nHRU, /allocate_heap)

; initialze counter
ixCount=0

; loop through HRUs
for iHRU=0,nHRU-1 do begin

 ; check there actually are overlaps
 if(nOverlap_remap[iHRU] gt 0) then begin

  ; save structure
  i1 = ixCount
  i2 = ixCount + nOverlap_remap[iHRU] - 1
  *(remap[iHRU]) = {hruId:     hruId_remap[iHRU],      $  ; HRU id
					weight:    weight_remap[i1:i2],    $  ; weights assigned to overlapping NLDAS polygons
					idOverlap: idOverlap_remap[i1:i2], $  ; id of overlapping NLDAS polygons
					iIndex:    iIndex_remap[i1:i2],    $  ; i-index of overlapping NLDAS polygons
					jIndex:    jIndex_remap[i1:i2]}       ; j-index of overlapping NLDAS polygons
  if(max(abs(idOrig_remap[i1:i2] - hruId_remap[iHRU])) gt 0)then stop, 'unexpected match in reading ragged arrays'
  
  ; increment counter
  ixCount = ixCount + nOverlap_remap[iHRU]
  if(iHRU mod 100000 eq 0)then print, 'Creating remapping structure: ', iHRU, nHRU

 ; no overlaps
 endif else begin
  *(remap[iHRU]) = {hruId:     hruId_remap[iHRU]}
 endelse

endfor  ; looping through HRUs

; test
iStart=3223L
for iHRU=iStart,iStart+10 do begin
 print, 'test: id = ', (*(remap[mizu2remap[iHRU]])).hruId, hruId_mizu[iHRU]
endfor

; *****
; * READ THE PFAFSTETTER CODES...
; *******************************

nc_filepath = '/Volumes/d1/mclark/NHD_Plus/ancillary_data/'
nc_filename = nc_filepath + 'conusPfafstetter_aggregate.nc'
print, 'Reading the Pfafstetter code'

; open file
ncid = ncdf_open(nc_filename, /nowrite)

; read the HRU ID
varid = ncdf_varid(ncid, 'hruId')
ncdf_varget, ncid, varid, hruId_pfaf

; read the segment ID
varid = ncdf_varid(ncid, 'segId')
ncdf_varget, ncid, varid, segId_pfaf

; read the pfafstetter code for stream segments
varid = ncdf_varid(ncid, 'pfafCode_cat')
ncdf_varget, ncid, varid, pCode_catchment

; read the pfafstetter code for stream segments
varid = ncdf_varid(ncid, 'pfafCode_seg')
ncdf_varget, ncid, varid, pCode_flowline

; read the pfafstetter class for catchments
varid = ncdf_varid(ncid, 'pfafClass_cat')
ncdf_varget, ncid, varid, pClass_catchment

; read the pfafstetter class for stream segments
varid = ncdf_varid(ncid, 'pfafClass_seg')
ncdf_varget, ncid, varid, pClass_flowline

; close file
ncdf_close, ncid

; re-order vectors for catchments
pCode_cat  = strarr(nHRU)
pClass_cat = strarr(nHRU)
pCode_cat[ sort(hruId_mizu)] = strtrim(pCode_catchment[ sort(hruId_pfaf)], 2)
pClass_cat[sort(hruId_mizu)] = strtrim(pClass_catchment[sort(hruId_pfaf)], 2)

; re-order vectors for streamflow
pCode_seg  = strarr(nSeg)
pClass_seg = strarr(nSeg)
pCode_seg[ sort(segId_mizu)] = strtrim(pCode_flowline[ sort(segId_pfaf)], 2)
pClass_seg[sort(segId_mizu)] = strtrim(pClass_flowline[sort(segId_pfaf)], 2)

; *****
; * AGGREGATE THE MIZUROUTE NETWORK TOPOLOGY FILE...
; **************************************************

; intialize indices
ixIndex_cat = 0
ixIndex_seg = 0
 
; define shapefile types
shpType = ['Catchment_', 'Flowline_']

; loop through shapefiles
for iFile=0,n_elements(nhdFiles)/2-1 do begin

 ; loop through shapefile types
 for iType=0,n_elements(shpType)-1 do begin

  ; define the original shapefile
  shpFile_orig = shp_path + shpType[iType] + nhdFiles[0,iFile] + '_' + nhdFiles[1,iFile] + '.shp'
  print, shpFile_orig

  ; define the aggregated shapefile
  if(shpType[iType] eq 'Catchment_')then hruShpFile_agg = shp_root + 'nhdPlus_SHPs_aggregate/' + shpType[iType] + nhdFiles[0,iFile] + '_' + nhdFiles[1,iFile] + '-agg.shp'
  if(shpType[iType] eq 'Flowline_')then  segShpFile_agg = shp_root + 'nhdPlus_SHPs_aggregate/' + shpType[iType] + nhdFiles[0,iFile] + '_' + nhdFiles[1,iFile] + '-agg.shp'

  ; get the feature ID
  if(shpType[iType] eq 'Catchment_')then get_attributes, shpFile_orig, 'FEATUREID', hruId_sh
  if(shpType[iType] eq 'Flowline_')then  get_attributes, shpFile_orig, 'COMID',     segId_sh

  ; get the shapes
  if(shpType[iType] eq 'Catchment_')then get_shapes, shpFile_orig, hru_shapes
  if(shpType[iType] eq 'Flowline_')then  get_shapes, shpFile_orig, seg_shapes

  ; get the match
  matchName = savePath + 'matchShapeMizuRoute_' + shpType[iType] + nhdFiles[0,iFile] + '_' + nhdFiles[1,iFile] + '.sav'
  ;spawn, 'rm ' + matchName
  if(file_test(matchName) eq 0)then begin
   print, 'Matching the file ', matchName
   if(shpType[iType] eq 'Catchment_')then begin
    match, hruId_mizu, hruID_sh, hruId_mizu_ix, hruID_sh_ix
    save, hruId_mizu_ix, hruID_sh_ix, filename=matchName
   endif else begin
    match, segId_mizu, segID_sh, segId_mizu_ix, segID_sh_ix
    save, segId_mizu_ix, segID_sh_ix, filename=matchName
   endelse
  endif else begin
   print, 'Restoring the file ', matchName
   restore, matchName
  endelse

 endfor  ; looping through shapefile types

 ; get a subset of mapping indices
 nSubset   = n_elements(hruId_mizu_ix)
 iySeg2hru = replicate(-9999LL, nHRU)
 iySeg2hru[hruId_mizu_ix] = lindgen(nSubset)

 ; get a second subset of mapping indices 
 izSeg2hru = replicate(-9999, nSubset)

 ; get the regional subset for catchments
 classVec_cat = strtrim(pClass_cat[hruId_mizu_ix],2)
 codeVec_cat  = strtrim(pCode_cat[hruId_mizu_ix],2)

 ; get the regional subset for stream segments
 classVec_seg = strtrim(pClass_seg[segId_mizu_ix],2)
 codeVec_seg  = strtrim(pCode_seg[segId_mizu_ix],2)

 ; get the unique codes for stream segments
 uniqVec      = classVec_seg[uniq(classVec_seg, sort(classVec_seg))]
 
 ; remove zero codes
 if(uniqVec[0] eq '0')then uniqVec = temporary(uniqVec[1:n_elements(uniqVec)-1])
 nUnique  = n_elements(uniqVec)
 
 ; get the first three digits of the string
 classString_cat = strmid(strtrim(classVec_cat,2),0,3)
 classString_seg = strmid(strtrim(classVec_seg,2),0,3)
 uniqString      = strmid(strtrim(uniqVec,2),0,3)

 ; define catchment variables
 hruId_agg   = replicate(0LL,       nUnique*2L) ; ID of each HRU
 hru2seg_agg = replicate(0LL,       nUnique*2L) ; ID of the stream segment below each HRU
 hruArea_agg = replicate(-9999.d,   nUnique*2L) ; hru area
 
 ; define stream variables
 segId_agg     = replicate(0LL,     nUnique)    ; ID of each stream segment
 dwnSegId_agg  = replicate(0LL,     nUnique)    ; ID downstream of each stream segment
 segSlope_agg  = replicate(-9999.d, nUnique)    ; segment slope
 segLength_agg = replicate(-9999.d, nUnique)    ; segment length

 ; define spatial mapping variables
 nOverlap_agg  = replicate(-9999L,  nUnique*2L) ; number of grids overlapping each polygon

 ; check that we have all catchments
 nCatchments  = n_elements(hruId_sh)
 gotCatchment = replicate(0, nCatchments)

 ; define the firct catchment
 firstCatchment = 0
 
 ; focus on smaller areas
 for iRegion=1,9 do begin
  for iPfaf1=0,9 do begin
   for iPfaf2=0,9 do begin
  
    ; define starting Pfafstetter code
    prefix  = strtrim(iRegion,2) + strtrim(iPfaf1,2) + strtrim(iPfaf2,2)
    ;prefix   = '968'
  
    ; get regional subsets (reduce computational time for searching)
    ixClass_cat = where(classString_cat eq prefix, nClass_cat)
    ixClass_seg = where(classString_seg eq prefix, nClass_seg)

    ; get unique string (shared among catchments and stream segments)
    ixUniq  = where(uniqString eq prefix, nUniq)
    if(nUniq eq 0)then continue
  
    ; loop through unique strings for the regional subset
    for iUniq=0,nUniq-1 do begin

     ; *****
     ; * GET INDICES FOR THE STREAMS AND CATCHMENTS...
     ; ***********************************************

     ; define the unique id
     idUnique = uniqVec[ixUniq[iUniq]]
 
     ;print, '*****'
     ;print, '*****'
     ;print, '*****'
     ;print, 'idUnique = ', idUnique
 
     ; get the indices for the stream segments
     ixStream = where(classVec_seg[ixClass_seg] eq idUnique, nStream)
     if(nStream eq 0)then stop, 'Stream: expect at least one match with the unique code'
     iyStream = segId_mizu_ix[ixClass_seg[ixStream]]
     if(total(basArea_mizu[iyStream]) lt 0.1d)then continue

     ; get the indices for the catchments
     ixCatch = where(classVec_cat[ixClass_cat] eq idUnique, nCatch)
     if(nCatch eq 0)then stop, 'Catchment: expect at least one catchment'
     iyCatch = hruId_mizu_ix[ixClass_cat[ixCatch]]
     ;print, 'hruId_mizu = ', hruId_mizu[iyCatch]

     ; identify the HRUs that drain into stream segments
     doesHRUdrain = (hruSegIndex_mizu[iyCatch] ge 0)  
     ixDrain = where(doesHRUdrain eq 1, nDrain)
     ;print, 'idUnique, nCatch, nStream = ', idUnique, nCatch, nStream

     ; check areas
     if(nDrain gt 0)then begin
      if(abs(total(basArea_mizu[iyStream]) - total(hruArea_mizu[iyCatch[ixDrain]])) gt 1.d)then stop, 'area difference is greater than 1 m2'
     endif

     ; *****
     ; * DEFINE AGGREGATED RIVER NETWORK...
     ; ************************************

     ; identify the main stem
     get_mainStem, idUnique, codeVec_seg[ixClass_seg[ixStream]], isMainStem
     ixMainstem = where(isMainstem eq 1, nMainstem)
     if(nMainstem gt 0)then begin

      ; get subset of stream segments that are on the main stem
      izSubset   = ixClass_seg[ixStream[ixMainstem]] 
      iyMainstem = segId_mizu_ix[izSubset]  ; index in mizuRoute NetCDF file
      izMainstem = segID_sh_ix[izSubset]    ; index in shape file
      ;print, 'Pfafstetter main stem = ', pCode_seg[iyMainstem]

      ; check that we do not have multiple dangling reaches on the main stem
      ixOutlet   = where(downSegIndex_mizu[iyMainstem] lt 0, nOutlet)
      isDrainage = (max(totalArea_mizu[iyMainstem]) gt 0.1d)
      ;print, 'nOutlet    = ', nOutlet
      ;print, 'ixOutlet   = ', ixOutlet
      ;print, 'isDrainage = ', isDrainage

      ; check that there are meaningful areas for multiple drainages
      if(isDrainage eq 1)then begin
       if(nOutlet gt 1)then begin

        ; find the outlet with the largest area
        iyOutlet = iyMainstem[ixOutlet]
        areaMax  = max(totalArea_mizu[iyOutlet], ixMax)
        ;print, 'area = ', totalArea_mizu[iyOutlet]
        ;print, 'pfaf = ', pCode_seg[iyOutlet]

        ; get the subset of IDs for the basin with the largest area
        ixSubset = ixClass_seg[ixStream[ixMainstem]]
        desireId = strmid(pCode_seg[iyOutlet[ixMax]], 0, strlen(idUnique)+1)
        iySubset = where(strmid(pCode_seg[segId_mizu_ix[ixSubset]],0,strlen(idUnique)+1) eq desireId)
        ;print, 'pfaf1 = ', pCode_seg[segId_mizu_ix[ixSubset]]
        ;print, 'pfaf2 = ', pCode_seg[segId_mizu_ix[ixSubset[iySubset]]]

        ; identify the main stem
        get_mainStem, desireId, codeVec_seg[ixSubset[iySubset]], isMainStem
        ixMainstem = where(isMainstem eq 1, nMainstem)
        if(nMainstem eq 0)then stop, 'expect one main stem when there are multiple outlets'

        ; get subset of stream segments that are on the main stem
        izSubset   = ixSubset[iySubset[ixMainstem]]
        iyMainstem = segId_mizu_ix[izSubset]  ; index in mizuRoute NetCDF file
        izMainstem = segID_sh_ix[izSubset]    ; index in shape file
        ;print, 'dissolving multiple main stem elements = ', pCode_seg[iyMainstem]

       endif ; special case of multiple outlets

       ; identify the elements connected to the reach with the largest area 
       if(nMainstem gt 0)then begin

        ; identify the index of the basin with largest area (iyMax) as well as the index of the downstream basin (iyDown)
        get_downstream, iyMainstem, totalArea_mizu, pClass_seg, downSegIndex_mizu, iyMax, iyDown

        ; check if the reaches drain through the bottom basin
        check_downstream, iyMax, downSegIndex_mizu, iyMainstem, isDownstream
        ;print, 'isDownstream = ', isDownstream         

        ; identify the main stem again
        ixMainstem = where(isDownstream eq 1, nMainstem)
        if(nMainstem eq 0)then stop, 'expect one main stem for the largest outlet'

        ; get subset of stream segments that are on the main stem
        izSubset   = izSubset[ixMainstem]
        iyMainstem = segId_mizu_ix[izSubset]  ; index in mizuRoute NetCDF file
        izMainstem = segID_sh_ix[izSubset]    ; index in shape file
        ;print, 'restrict attention to the biggest main stem = ', pCode_seg[iyMainstem]

       endif  ; if more than one element on the main stem

       ; update the stream segment shapefile
       aggregateShapefile, typeStream, ixIndex_seg, long64(idUnique), segShpFile_agg, seg_shapes, izMainstem

      ; isDrainage=0
      endif else begin
       nMainstem=0  ; no mainstem if the stream segments have no area [used later]
      endelse  

     ; check
     endif else begin
      print, idUnique, ': no stream segments on the main stem'
      ;stop
     endelse

     ; *****
     ; * DEFINE AGGREGATED CATCHMENTS...
     ; *********************************

     ; update the catchment shapefile  - catchments that flow into the main stem

     ; identify the reaches that drain through to the bottom basin
     if(nMainstem gt 0)then begin

      ; get indices of stream segments that flow through the outlet
      check_downstream, iyMax, downSegIndex_mizu, iyStream, isNetwork
      ixDrain = where(isNetwork eq 1, nDrain)
      if(nDrain eq 0)then stop, 'expect some stream segments flow to the outlet when there is a mainstem'

      ; get indices of catchments connected to the stream network
      izDrain  = segId_mizu_ix[ixClass_seg[ixStream[ixDrain]]]  ; segId index in the mizuroute vector
      ixRunoff = ixSeg2hru[izDrain]                             ; hru index in mizuroute vector
      ixMatch  = where(ixRunoff ge 0, nRunoff)                  ; some stream segments do not have an associated catchment
      if(nRunoff eq 0)then stop, 'expect some catchments flow to the outlet'
      if(nRunoff gt nCatch)then stop, 'cannot have more catchments than in the subset'
      iyRunoff = ixRunoff[ixMatch]     ; subset of indices in the full mizuroute vector
      izCatch  = iySeg2hru[iyRunoff]   ; subset of indices in the regional subset
      ;print, 'hruId_mizu = ', hruId_mizu[iyRunoff]
      ;print, 'ixIndex_cat = ', ixIndex_cat

      ; define catchments that flow to the main stem
      aggregateShapefile, typeCatch,  ixIndex_cat, long64(idUnique), hruShpFile_agg, hru_shapes, hruID_sh_ix[izCatch]

      ; save the indices that flow to the main stem
      izMainflow = hruId_mizu_ix[izCatch]

     ; no catchments flow to the main stem
     endif else begin

      ; define catchments that ***DO NOT*** flow to the main stem
      nRunoff = 0
      izCatch = ixClass_cat[ixCatch]
      aggregateShapefile, typeCatch,  ixIndex_cat, long64(idUnique+'01'), hruShpFile_agg, hru_shapes, hruID_sh_ix[izCatch]

      ; save the indices that flow nowhere
      izNowhere = hruId_mizu_ix[izCatch]

     endelse  ; no catchments flow to the main stem

     ; get indices of catchments that do *NOT* drain to the stream network

     ; special case where some catchments are disconnected to the stream network
     if(nRunoff gt 0 and nRunoff lt nCatch)then begin

      ; increment counter since there are some catchments that are not connected to the main stem
      ;   -- call to aggregateShapefile above
      ixIndex_cat = ixIndex_cat+1
      isItSpecial = 1

      ; define vector of catchments that is not routed
      isRouted = replicate(0, nCatch)
      izSeg2hru[izCatch] = lindgen(nRunoff)
      isRouted[izSeg2hru[izCatch]] = 1
      ixNoFlow = where(isRouted eq 0, nNoFlow)
      if(nNoFlow eq 0)then stop, 'expect some catchments do NOT drain to the river network'

      ; define catchments that ***DO NOT*** flow to the main stem
      izCatch = ixClass_cat[ixCatch[ixNoFlow]]
      aggregateShapefile, typeCatch,  ixIndex_cat, long64(idUnique+'01'), hruShpFile_agg, hru_shapes, hruID_sh_ix[izCatch]

      ; save the indices that flow nowhere
      izNowhere = hruId_mizu_ix[izCatch]

     endif else begin   ; special case where some catchments are disconnected to the stream network 
      isItSpecial = 0
     endelse

     ; get flag to denote the fate of the flow
     doesFlowSink  = (nRunoff lt nCatch)
     doesFlowDrain = (nMainstem gt 0)

     ; *****
     ; * GET THE DOWNSTREAM REACH ID...
     ; ********************************

     ; check that there is a main stem
     if(nMainstem gt 0)then begin
      ; identify the index of the basin with largest area (iyMax) as well as the index of the downstream basin (iyDown)
      get_downstream, iyMainstem, totalArea_mizu, pClass_seg, downSegIndex_mizu, iyMax, iyDown
     endif else begin
      iyDown = -1L  ; no main stem, so downstream reach is undefined
     endelse

     ; *****
     ; * GET THE CATCHMENT INDICES...
     ; ******************************

     ; define catchment types
     isItNowhere=1001
     isItMainflow=1002
     iLook_type=[isItNowhere,isItMainflow]

     ; check that the number of catchments is correct
     if(n_elements(izMainflow)*doesFlowDrain + n_elements(izNowhere)*doesFlowSink ne nCatch)then stop, 'unexpected number of catchments'

     ; rewind index
     ixIndex_cat = ixIndex_cat - isItSpecial

     ; loop through mainstem/nowhere
     for iType=0,n_elements(iLook_type)-1 do begin

      ; *****
      ; * AGGREGATE REMAPPING FILE...
      ; *****************************

      ; check that the subset exists
      case iLook_type[iType] of
       isItNowhere:  doIt = doesFlowSink
       isItMainflow: doIt = doesFlowDrain
       else: stop, 'unknown flow type'
      endcase
      if(doIt eq 0)then continue

      ; get the catchment indices
      case iLook_type[iType] of
       isItNowhere:  iySubset = izNowhere
       isItMainflow: iySubset = izMainflow
       else: stop, 'unknown flow type'
      endcase

      ; loop through catchments in the aggregation
      for iCatch=0,n_elements(iySubset)-1 do begin
  
       ; get the catchment ID in the remapping file
       izCatch = mizu2remap[iySubset[iCatch]]
       if((*(remap[izCatch])).hruId ne hruId_mizu[iySubset[iCatch]])then stop, 'cannot identify catchment in remapping file'
  
       ; get the number of overlaps
       nOverlap = nOverlap_remap[izCatch]
       if(n_elements((*(remap[izCatch])).idOverlap) ne nOverlap)then stop, 'unexpected number of overlapping polygons'
  
       ; save vectors
       iIndex_temp      = (*(remap[izCatch])).iIndex
       jIndex_temp      = (*(remap[izCatch])).jIndex
       idOverlap_temp   = (*(remap[izCatch])).idOverlap
       areaOverlap_temp = (*(remap[izCatch])).weight * hruArea_mizu[iySubset[iCatch]]
  
       ; save the remapping data
       if(iCatch eq 0)then begin
        iIndex      = iIndex_temp
        jIndex      = jIndex_temp
        idOverlap   = idOverlap_temp
        areaOverlap = areaOverlap_temp
       endif else begin
        iIndex      = [iIndex, iIndex_temp]
        jIndex      = [jIndex, jIndex_temp]
        idOverlap   = [idOverlap, idOverlap_temp]
        areaOverlap = [areaOverlap, areaOverlap_temp]
       endelse
  
      endfor  ; looping through catchments
  
      ; find unique matches
      uniqOverlap = idOverlap[uniq(idOverlap, sort(idOverlap))]
      nOverlap    = n_elements(uniqOverlap)
      if(nOverlap eq 0)then stop, 'expect at least one unique overlapping polygon' 
  
      ; compute total area of the aggregated polygon
      totalArea = total(hruArea_mizu[iySubset])
  
      ; save the number of overlaps
      nOverlap_agg[ixIndex_cat] = nOverlap
  
      ; define vectors
      iIndex_new  = lonarr(nOverlap)    ; i-index in overlapping grid
      jIndex_new  = lonarr(nOverlap)    ; j-index in overlapping grid
      idGrid_new  = lonarr(nOverlap)    ; id of overlapping grid
      weights_new = dblarr(nOverlap)    ; weight assigned to overlapping grid
  
      ; define check vector
      ixCheck = replicate(0, n_elements(areaOverlap))
  
      ; loop through unique polygons
      for iUnique=0,nOverlap-1 do begin
  
       ; get indices of unique polygons
       ixMatch = where(idOverlap eq uniqOverlap[iUnique], nMatch)
       if(nMatch eq 0)then stop, 'expect to match a unique polygon'
  
       ; save the IDs
       iIndex_new[iUnique] = iIndex[ixMatch[0]]    ; all matched values are the same 
       jIndex_new[iUnique] = jIndex[ixMatch[0]]    ; all matched values are the same 
       idGrid_new[iUnique] = idOverlap[ixMatch[0]] ; all matched values are the same 
  
       ; compute the weights
       weights_new[iUnique] = total(areaOverlap[ixMatch]) / totalArea
  
       ; check
       if(max(ixCheck[ixMatch]) eq 1)then stop, 'some elements processed already' 
       ixCheck[ixMatch] = 1
  
      endfor  ; looping through unique polygons
  
      ; checks
      if(abs(1.d - total(weights_new)) gt 1.d-4)then stop, 'weights do not sum to one'
      if(min(ixCheck) eq 0)then stop, 'some grids not processed'
  
      ; save the remapping data
      if(firstCatchment eq 0)then begin
       iIndex_agg  = iIndex_new
       jIndex_agg  = jIndex_new
       idGrid_agg  = idGrid_new
       weights_agg = weights_new
       firstCatchment = 1
      endif else begin
       iIndex_agg  = [iIndex_agg,  iIndex_new]
       jIndex_agg  = [jIndex_agg,  jIndex_new]
       idGrid_agg  = [idGrid_agg,  idGrid_new]
       weights_agg = [weights_agg, weights_new]
      endelse 

      ; *****
      ; * SAVE AGGREGATED ATTRIBUTES...
      ; *******************************

      ; get IDs
      case iLook_type[iType] of
       isItNowhere:  idElement = long64(idUnique+'01') 
       isItMainflow: idElement = long64(idUnique)
       else: stop, 'unknown flow type'
      endcase

      ; get hru IDs
      hruId_agg[ixIndex_cat] = idElement

      ; get segment IDs
      if(iLook_type[iType] eq isItMainflow)then begin
       segId_agg[ixIndex_seg]    = idElement    ; stream segment ID is the same as the HRU ID
       hru2seg_agg[ixIndex_cat]  = idElement    ; stream segment ID is the same as the HRU ID
      endif else begin
       hru2seg_agg[ixIndex_cat]  = -1L          ; HRU does not drain to any stream segment
      endelse

      ; get downstream ID
      if(iLook_type[iType] eq isItMainflow)then begin
       if(iyDown ge 0)then dwnSegId_agg[ixIndex_seg] = long64(pClass_seg[iyDown])
      endif
   
      ; get catchment area
      hruArea_agg[ixIndex_cat] = totalArea
      
      ; get stream length and slope
      if(iLook_type[iType] eq isItMainflow)then begin
       segLength_agg[ixIndex_seg] = total(segLength_mizu[iyMainstem])
       segSlope_agg[ixIndex_seg]  = total(segLength_mizu[iyMainstem]*segSlope_mizu[iyMainstem]) / segLength_agg[ixIndex_seg]
      endif

      ; print progress
      print, ixIndex_cat, iUniq, nUniq, hruId_agg[ixIndex_cat]
    
      ; increment index
      ixIndex_cat = ixIndex_cat+1
      if(iLook_type[iType] eq isItMainflow)then ixIndex_seg = ixIndex_seg+1  

     endfor  ; looping through file types
    endfor  ; looping through unique ids
  
   endfor  ; ipfaf2
  endfor  ; ipfaf1
 endfor  ; region

 ; get the number of catchments and stream segments
 nCatch  = ixIndex_cat
 nStream = ixIndex_seg

 ; *****
 ; * DEFINE AGGREGATED NETWORK TOPOLOGY FILE...
 ; ********************************************

 ; define the NetCDF file
 nc_filepath = '/Volumes/d1/mclark/NHD_Plus/ancillary_data/'
 nc_filename = nc_filepath + 'network_' + nhdFiles[0,iFile] + '_' + nhdFiles[1,iFile] + '-agg.nc'

 ; create file
 print, 'Creating the aggregated NetCDF file for the network topology'
 ncid = ncdf_create(nc_filename, /clobber, /netcdf4_format)

  ; create dimension
  hruId = ncdf_dimdef(ncid, 'hru', nCatch)
  segId = ncdf_dimdef(ncid, 'seg', nStream)

  ; create the HRU variables
  varid = ncdf_vardef(ncid, 'hruId',        [hruId], /uint64)
  varid = ncdf_vardef(ncid, 'hru2seg',      [hruId], /uint64)
  varid = ncdf_vardef(ncid, 'hruLocalArea', [hruId], /double)

  ; create the stream segment variables
  varid = ncdf_vardef(ncid, 'segId',        [segId], /uint64)
  varid = ncdf_vardef(ncid, 'downSegId',    [segId], /uint64)
  varid = ncdf_vardef(ncid, 'segLength',    [segId], /double)
  varid = ncdf_vardef(ncid, 'segSlope',     [segId], /double)

 ; end file definitions
 ncdf_control, ncid, /endef
 ncdf_close, ncid

 ; write the data
 ncid = ncdf_open(nc_filename, /write)

  ; write the HRU variables
  ncdf_varput, ncid, ncdf_varid(ncid, 'hruId'    ),      hruId_agg[0:nCatch-1]      ; ID of each HRU   
  ncdf_varput, ncid, ncdf_varid(ncid, 'hru2seg'  ),      hru2seg_agg[0:nCatch-1]    ; ID of the stream segment below each HRU 
  ncdf_varput, ncid, ncdf_varid(ncid, 'hruLocalArea'),   hruArea_agg[0:nCatch-1]    ; hru area         

  ; write the stream segment variables
  ncdf_varput, ncid, ncdf_varid(ncid, 'segId'    ),      segId_agg[0:nStream-1]     ; ID of each stream segment  
  ncdf_varput, ncid, ncdf_varid(ncid, 'downSegId'),      dwnSegId_agg[0:nStream-1]  ; ID downstream of each stream segment
  ncdf_varput, ncid, ncdf_varid(ncid, 'segLength'),      segLength_agg[0:nStream-1] ; segment length   
  ncdf_varput, ncid, ncdf_varid(ncid, 'segSlope' ),      segSlope_agg[0:nStream-1]  ; segment slope

 ; close netcdf file
 ncdf_close, ncid

 ; *****
 ; * DEFINE AGGREGATED SPATIAL WEIGHTS FILE...
 ; *******************************************

 ; get the total number of overlapping IDs
 nOverlap = n_elements(idGrid_agg)

 ; define the NetCDF file
 nc_filepath = '/Volumes/d1/mclark/NHD_Plus/ancillary_data/'
 nc_filename = nc_filepath + 'spatialWeights_' + nhdFiles[0,iFile] + '_' + nhdFiles[1,iFile] + '-agg.nc'

 ; create file
 print, 'Creating the aggregated NetCDF file for the spatial weights'
 ncid = ncdf_create(nc_filename, /clobber, /netcdf4_format)

  ; create dimension
  hruId     = ncdf_dimdef(ncid, 'hru',     nCatch)
  overlapId = ncdf_dimdef(ncid, 'overlap', nOverlap)

  ; create the HRU variables
  varid = ncdf_vardef(ncid, 'hruId',     [hruId], /uint64)
  varid = ncdf_vardef(ncid, 'nOverlaps', [hruId], /long)

  ; create the overlap variables
  varid = ncdf_vardef(ncid, 'weight',    [overlapId], /double)
  varid = ncdf_vardef(ncid, 'i_index',   [overlapId], /long)
  varid = ncdf_vardef(ncid, 'j_index',   [overlapId], /long)
  varid = ncdf_vardef(ncid, 'id_grid',   [overlapId], /long)

 ; end file definitions
 ncdf_control, ncid, /endef
 ncdf_close, ncid

 ; write the data
 ncid = ncdf_open(nc_filename, /write)

  ; write the HRU variables
  ncdf_varput, ncid, ncdf_varid(ncid, 'hruId'    ), hruId_agg[0:nCatch-1]     ; ID of each HRU   
  ncdf_varput, ncid, ncdf_varid(ncid, 'nOverlaps'), nOverlap_agg[0:nCatch-1]  ; number of grids that overlap the polygon 

  ; write the overlap variables
  ncdf_varput, ncid, ncdf_varid(ncid, 'i_index'),    iIndex_agg   ; i-index in overlapping grid         
  ncdf_varput, ncid, ncdf_varid(ncid, 'j_index'),    jIndex_agg   ; j-index in overlapping grid         
  ncdf_varput, ncid, ncdf_varid(ncid, 'id_grid'),    idGrid_agg   ; id of overlapping grid              
  ncdf_varput, ncid, ncdf_varid(ncid, 'weight'),     weights_agg  ; weight assigned to overlapping grid 

 ; close netcdf file
 ncdf_close, ncid

 stop, 'completed region'

endfor  ; looping through shapefiles

stop
end
