# used to get the EPSG code from a lon/lat string
# from: https://geocompr.robinlovelace.net/reproj-geo-data.html
lonlat2UTM = function(lonlat) {
  utm = (floor((lonlat[1] + 180) / 6) %% 60) + 1
  if(lonlat[2] > 0) {
    utm + 32600
  } else{
    utm + 32700
  }
}
