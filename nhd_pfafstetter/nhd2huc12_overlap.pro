pro nhd2huc12_overlap

; used to identify the dominant HUC-12 polygon for each NHD+ basin

; *****
; * READ DATA...
; **************

; define IDL save file
savePath = '/Volumes/d1/mclark/NHD_Plus/ancillary_data/idlSave/'
saveName = savePath + 'nhd2huc12_overlap.sav'

; check if the idl save file exists
if(file_test(saveName) eq 0)then begin ; save file does not exist -- create it

 ; open file and read header
 cHeader  = '.'
 tsv_path = '/Volumes/d1/mclark/NHD_Plus/ancillary_data/nhd2huc12/'
 tsv_file = tsv_path + 'nhd_wbd_intersection.tsv'
 openr, in_unit, tsv_file, /get_lun
 readf, in_unit, cHeader
 
 ; define data
 cData  = '.'
 nData  = file_lines(tsv_file)-1 ; -1 because of the header
 comid  = lon64arr(nData)
 huc12  = lon64arr(nData)
 weight = dblarr(nData)
 
 ; read data
 for iData=0L,nData-1 do begin
 
  ; read data and extract the vector
  readf, in_unit, cData
  cVector = strsplit(cData, string(9B), /extract)
  if(n_elements(cVector) ne 3)then stop, 'expect a 3-element vector'
  comid[iData] = long64(cVector[0])
 
  ; save valid data
  if(strtrim(cVector(1),2) ne 'NA')then begin
   huc12[iData]  = long64(cVector[1])
   weight[iData] = double(cVector[2])
 
  ; assign missing values
  endif else begin
   huc12[iData]  = -9999LL 
   weight[iData] = -9999.d
  endelse
 
  ; print progress
  if(iData mod 100000L eq 0L)then print, 'Reading data: ', iData, nData, cVector
 
 endfor ; looping through data
 
 ; free up file unit
 free_lun, in_unit
 
 ; save file
 save, comid, huc12, weight, filename=saveName 

; idl save file exists
endif else begin
 restore, saveName
endelse

; *****
; * IDENTIFY DOMINANT HUC-12 POLYGON...
; *************************************

; sort the comID
ixSort = sort(comid)
print, comid[ixSort[0:10]]

ixUniq = uniq(comid, ixSort)
print, ixUniq[0:10]


stop
end
