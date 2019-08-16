#' connectPoints
#' @description get two points closest to a line
connectPoints <- function(shapes, feature) {

# arguments
# shapes  = collection of line segments for a given landmass
# feature = target feature to match (line or point)

 # get midpoint in each line segment
points   <- st_line_sample(shapes, 1, type="regular")
points   <- st_as_sf(cbind(st_drop_geometry(shapes), points))
points   <- points %>% st_cast("POINT")

# get the line segment closest to the desired feature
#  and cast the closest line segment as a set of points
ixClose  <- st_nearest_feature(feature, points)
pClose   <- shapes[ixClose,] %>% st_cast("POINT")




# return the closest TWO points
pDist    <- st_distance(pClose, line)
return(pClose[order(pDist)[1:2],])
}
