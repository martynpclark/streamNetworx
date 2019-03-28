pro buildNetCDF

; used to write Pfafsteter codes to NetCDF files

; get path to NHD-plus
nhd_root = '/Users/mac414/geospatial_data/NHD_Plus/ancillary_data/'

; define path for .sav files
savePath = nhd_root + 'idlSave/'

; Define shapefiles
nhdFiles = [$
            ['PN','17' ], $
            ['CA','18' ], $
            ['RG','13' ], $
            ['GB','16' ], $
            ['SR','09' ], $
            ['SA','03N'], $
            ['NE','01' ], $
            ['MA','02' ], $
            ['SA','03W'], $
            ['SA','03S'], $
            ['GL','04' ], $
            ['MS','05' ], $
            ['MS','06' ], $
            ['MS','07' ], $
            ['MS','08' ], $
            ['MS','10U'], $
            ['MS','10L'], $
            ['MS','11' ], $
            ['CO','14' ], $
            ['CO','15' ], $
            ['TX','12' ], $
            ['MA','02' ]  ]

; *****
; * READ THE NHD+ TOPOLOGY...
; ***************************

; define the NetCDF file
nc_filename = nhd_root + 'NHDPlus2_updated-CONUS.nc'
print, 'Reading ancillary file'

; open file
nc_file = ncdf_open(nc_filename, /nowrite)

 ; get the basin id
 ivar_id = ncdf_varid(nc_file,'idFeature')
 ncdf_varget, nc_file, ivar_id, hruId_mizu

 ; get the segid
 ivar_id = ncdf_varid(nc_file,'link')
 ncdf_varget, nc_file, ivar_id, segId_mizu

 ; get the total area
 ivar_id = ncdf_varid(nc_file,'totalArea')
 ncdf_varget, nc_file, ivar_id, totalArea_mizu

; close file
ncdf_close, nc_file

; get the number of segments and HRUs
nHRU = n_elements(hruId_mizu)
nSeg = n_elements(segId_mizu)

; *****
; * DEFINE THE PFAFSTETTER NETCDF FILE...
; ***************************

; define the NetCDF file
nc_filename = nhd_root + 'conusPfafstetter.nc'
spawn, 'rm ' + nc_filename

; create file
if(file_test(nc_filename) eq 0)then begin

 ; open file (clobber)
 print, 'Creating the NetCDF file for the Pfafstetter code'
 ncid = ncdf_create(nc_filename, /clobber, /netcdf4_format)

  ; create dimension
  dimId_hru = ncdf_dimdef(ncid, 'hru', nHRU)
  dimId_seg = ncdf_dimdef(ncid, 'seg', nSeg)

  ; create the basin variables
  varid = ncdf_vardef(ncid, 'hruId',        [dimid_hru], /long)
  varid = ncdf_vardef(ncid, 'pfafCode_hru', [dimid_hru], /string)

  ; create the segment variables
  varid = ncdf_vardef(ncid, 'segId',        [dimid_seg], /long)
  varid = ncdf_vardef(ncid, 'pfafCode_seg', [dimid_seg], /string)

 ; end file definitions
 ncdf_control, ncid, /endef
 ncdf_close, ncid

endif  ; if creating file

; write the Ids
ncid = ncdf_open(nc_filename, /write)

 ; write the hruId
 varid = ncdf_varid(ncid, 'hruId')
 ncdf_varput, ncid, varid, hruId_mizu

 ; write the segId
 varid = ncdf_varid(ncid, 'segId')
 ncdf_varput, ncid, varid, segId_mizu

; close file
ncdf_close, ncid

; ----------------------------------------------------------------------------------------------------------
; ----------------------------------------------------------------------------------------------------------
; ----------------------------------------------------------------------------------------------------------
; ----------------------------------------------------------------------------------------------------------

; define conus vectors
pfafHRU_conus = replicate('0', nHRU)
pfafSeg_conus = replicate('0', nSeg)

; loop through shapefiles
for iFile=0,n_elements(nhdFiles)/2-1 do begin

 ; *****
 ; * GET INFORMATION FROM THE SHAPEFILES...
 ; ****************************************

 ; define NHD string
 nhdString = nhdFiles[0,iFile] + '_' + nhdFiles[1,iFile]
 print, 'Merging ' + nhdString

 ; define shapefiles
 shpFile_hru   = nhd_root + 'nhdPlus_SHPs_noDuplicate/Catchment_' + nhdString + '.shp'
 shpFile_seg   = nhd_root + 'nhdPlus_SHPs_noDuplicate/Flowline_'  + nhdString + '.shp'

 ; get the basin pfafCodes
 get_attributes, shpFile_hru, 'FEATUREID', featId_sh
 get_attributes, shpFile_hru, 'pfafCode',  pfafCode_hru

 ; get the segment pfafCodes
 get_attributes, shpFile_seg, 'COMID',    comId_sh
 get_attributes, shpFile_seg, 'pfafCode', pfafCode_seg

 ; check that the hru strings are OK
 maxLength = max(strlen(pfafCode_hru), iMax)
 if(strtrim(long64(pfafCode_hru[iMax]),2) ne pfafCode_hru[iMax])then begin
  print, 'SERIOUS ERROR: hru string is too long ', maxLength, ': ', pfafCode_hru[iMax]
  stop
 endif

 ; check that the seg strings are OK
 maxLength = max(strlen(pfafCode_seg), iMax)
 if(strtrim(long64(pfafCode_seg[iMax]),2) ne pfafCode_seg[iMax])then begin
  print, 'SERIOUS ERROR: seg string is too long ', maxLength, ': ', pfafCode_seg[iMax]
  stop
 endif

 ; *****
 ; * GET SUBSET OF REACHES IN A SPECIFIC REGION...
 ; ***********************************************
 
 ; define unique string for save files
 nameRegion = nhdFiles[0,iFile] + '_' + nhdFiles[1,iFile]

 ; match the netcdf hru id
 matchName = savePath + 'matchMizu_catchments_' + nameRegion + '.sav'
 if(file_test(matchName) eq 0)then begin
  print, 'Matching the file ' + matchName
  match, hruId_mizu, featId_sh, hruId_mizu_ix, featID_sh_ix
  save, hruId_mizu_ix, featID_sh_ix, filename=matchName
 endif else begin
  restore, matchName
 endelse

 ; match the netcdf seg id
 matchName = savePath + 'matchMizu_nhdPlusFinal_' + nameRegion + '.sav'
 if(file_test(matchName) eq 0)then begin
  print, 'Matching the file ' + matchName
  match, segId_mizu, comID_sh, segId_mizu_ix, comID_sh_ix
  save, segId_mizu_ix, comID_sh_ix, filename=matchName
 endif else begin
  restore, matchName
 endelse

 ; get the subset of reaches
 pfafHRU_conus[hruId_mizu_ix] = pfafCode_hru[featID_sh_ix]
 pfafSeg_conus[segId_mizu_ix] = pfafCode_seg[comID_sh_ix]

endfor  ; looping through regions

; *****
; * CHECK... 
; **********

print, 'checking conus data'

; check that all HRUs are assigned
ixAssigned = where(long64(pfafHRU_conus) gt 0LL, nAssigned)
if(nAssigned lt nHRU)then stop, 'some HRUs are not assigned'

; check that all stream segments are assigned
ixAssigned = where(long64(pfafSeg_conus) gt 0LL, nAssigned)
if(min(totalArea_mizu[ixAssigned]) gt 0.1d)then stop, 'some stream segments are not assigned'

; *****
; * WRITE THE PFAFSTETTER CODE...
; *******************************

; open NetCDF file 
ncid    = ncdf_open(nc_filename, /write)

print, 'Writing the Pfafstetter code for basins'
pfaf_id = ncdf_varid(ncid, 'pfafCode_hru')
ncdf_varput, ncid, pfaf_id, pfafHRU_conus

print, 'Writing the Pfafstetter code for stream segments'
pfaf_id = ncdf_varid(ncid, 'pfafCode_seg')
ncdf_varput, ncid, pfaf_id, pfafSeg_conus

; close NetCDF file
ncdf_close, ncid



stop
end
