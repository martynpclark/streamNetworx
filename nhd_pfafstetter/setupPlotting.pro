pro setupPlotting, x1, y1, x2, y2, xSize, ySize

; define plotting parameters
window, 0, xs=xSize, ys=ySize, retain=2;, /pixmap
device, decomposed=0
!P.MULTI=1

; define yes/no
yes=1
no=0

; define the desire to plot drainage area
plotStreamflow=yes

; check need to reverse color scale
if(plotStreamflow eq yes)then begin
 doReverse=no
endif else begin
 doReverse=yes
endelse

LOADCT, 39
; reverse color scale
if(doReverse eq yes)then begin
 tvlct, r, g, b, /get
 r = reverse(r)
 g = reverse(g)
 b = reverse(b)
 tvlct, r, g, b
 white=0
 black=255
endif else begin
 white=255
 black=0
endelse
; set defaults
!P.COLOR=black
!P.BACKGROUND=white
!P.CHARSIZE=2.5
!P.MULTI=1
erase, color=white

; make a base plot
plot, indgen(5), xrange=[160,200], yrange=[10,40], $
 xmargin=[1,1], ymargin=[1,1], xstyle=13, ystyle=13, /nodata

; set the map projection
map_set, 0.5*(y1+y2), 0.5*(x1+x2), /albers, limit=[y1,x1,y2,x2], /noborder

; make the map
map_continents, mlinethick=1

end

