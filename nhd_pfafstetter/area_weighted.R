library(dplyr)
library(sf)
library(testthat)
library(tictoc)

#' Area Weighted Intersection
#' @description Returns the fractional percent of each 
#' feature in y that is covered by each intersecting feature 
#' in x. These can be used as the weights in an area-weighted
#' mean overlay analysis where y is the data source and area-
#' weighted means are being generated for x. 
#' THIS WILL NOT WORK WITH SELF INTERSECTIONS!!!!!
area_weighted_intersection <- function(x, y) {
  
  # Standard evaluation is for chumps.
  tic("initialize....")
  id_x <- names(x)[names(x) != attr(x, "sf_column")]
  id_y <- names(y)[names(y) != attr(y, "sf_column")]
  names(x)[names(x) == id_x] <- "varx"
  names(y)[names(y) == id_y] <- "vary"
  toc()  # print timing  

  # Get all parts and calculate their individual area
  tic("st_intersection....")
  intersection <- st_intersection(x, y) %>%
    mutate(part_area = as.numeric(st_area(.))) %>%
    group_by(varx) %>% # Allow sum parts over each x.
    st_set_geometry(NULL)
  toc()  # print timing  
  
  # Get the area of x.
  tic("get area....")
  x_area <- mutate(x, x_area = as.numeric(st_area(x))) %>%
    st_set_geometry(NULL)
  toc()  # print timing  
  
  # Join the intersecting area with the all the parts.
  tic("right join....")
  intersection <- right_join(intersection, x_area, by = "varx")
  toc()  # print timing  
  
  # Join total x area and calculate percent for each sum of intersecting y.
  tic("finalize....")
  intersection <- mutate(intersection, w = part_area/x_area) %>%
    select(varx, vary, w) %>%
    ungroup()
  toc()  # print timing  
  
  out <-setNames(intersection, c(id_x, id_y, "w"))
  
  return(out)
}

#  b1 = st_polygon(list(rbind(c(-1,-1), c(1,-1), 
#  						   c(1,1), c(-1,1), 
#  						   c(-1,-1))))
#  b2 = b1 + 2
#  b3 = b1 + c(-0.2, 2)
#  b4 = b1 + c(2.2, 0)
#  b = st_sfc(b1, b2, b3, b4)
#  a1 = b1 * 0.8
#  a2 = a1 + c(1, 2)
#  a3 = a1 + c(-1, 2)
#  a = st_sfc(a1,a2,a3)
#  plot(b, border = 'red')
#  plot(a, border = 'green', add = TRUE)
#  
#  st_crs(b) <- st_crs(a) <- st_crs(5070)
#  
#  b <- st_sf(b, data.frame(idb = c(1, 2, 3, 4)))
#  a <- st_sf(a, data.frame(ida = c(1, 2, 3)))
#  
#  a_b <- area_weighted_intersection(a, b)
#  b_a <- area_weighted_intersection(b, a)
#  
#  test_that("a_b", {
#    expect_equal(as.numeric(a_b[1, ]), c(1,1,1), info = "a1 is 100% covered by b1.")
#    expect_equal(as.numeric(a_b[2, ]), c(2,2,0.5), info = "a2 is 50% covered by b2.")
#    expect_equal(as.numeric(a_b[3, ]), c(2,3,0.375), info = "a2 is 37.5% covered by b3.")
#    expect_equal(as.numeric(a_b[4, ]), c(3,3,0.625), info = "a3 is 62.5% covered by b3.")
#  })
#    
#  test_that("b_a", {
#    expect_equal(as.numeric(b_a[1, ]), c(1,1,0.64), info = "b1 is 64% covered by a1")
#    expect_equal(as.numeric(b_a[2, ]), c(2,2,0.32), info = "b2 is 32% covered by a2")
#    expect_equal(as.numeric(b_a[3, ]), c(3,2,0.24), info = "b3 is 24% covered by a2")
#    expect_equal(as.numeric(b_a[4, ]), c(3,3,0.4), info = "b3 is 40% covered by a3")
#    expect_equal(data.frame(b_a[5, ]), 
#  			   data.frame(tibble(idb = 4, 
#  								 ida = as.numeric(NA), 
#  								 w = as.numeric(NA))), info = "b4 is not covered")
#  })
