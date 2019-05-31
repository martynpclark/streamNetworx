library(foreign)
library(ncdf4)

#####
# DEFINE FILES...
#################

# define regional subset
subset <- "pfaf_71"

# define path to the hydrography
base_path <- "/Users/mac414/geospatial_data/MERIT-hydro/"
dbf_path  <- paste(base_path, "pfaf_level_02/",  sep="")
out_path  <- paste(base_path, "mizuRoute/ancillary_data/", sep="")

# define file suffix
dbfSuffix <- paste(subset, "_MERIT_Hydro_v07_Basins_v01_bugfix1.dbf", sep="")

# define input .dbf files
cat_dbf <- paste(dbf_path, "cat_", dbfSuffix, sep="")
riv_dbf <- paste(dbf_path, "riv_", dbfSuffix, sep="")

# define the output ancillary netcdf files
anc_ncdf <- paste(out_path, "mizuRouteNetwork_merit_", subset, ".nc", sep="")

#####
# READ THE DBF FILES...
#######################

cat <- read.dbf(cat_dbf)
riv <- read.dbf(riv_dbf)

#####
# WRITE INFORMATION TO THE NETCDF FILE...
#########################################

# remove the NetCDF file -- R does not seem to have a "clobber" option
system(paste("rm -f",anc_ncdf))

# define dimensions
cat_dim <- ncdim_def("cat", "", cat$COMID)
riv_dim <- ncdim_def("riv", "", riv$COMID)

# define catchment variables
catSegId_def  <- ncvar_def("catSegId",  "-",  cat_dim, -9999,  "ID of the stream segment below each HRU", prec="integer")
catArea_def   <- ncvar_def("catArea",   "m2", cat_dim, -9999., "catchment area", prec="double")

# define river variables
rivSlope_def  <- ncvar_def("rivSlope",  "-",  riv_dim, -9999., "river slope", prec="double")
rivLength_def <- ncvar_def("rivLength", "m",  riv_dim, -9999., "river length", prec="double")
rivDownId_def  <-ncvar_def("rivDownId", "-",  riv_dim, -9999,  "unique id of the next downstream segment", prec="integer")

# create NetCDF file
ncout <- nc_create(anc_ncdf,list(catSegId_def,catArea_def,rivSlope_def,rivLength_def,rivDownId_def),force_v4=T)

# put catchment variables
ncvar_put(ncout, catSegId_def  , cat$COMID)  
ncvar_put(ncout, catArea_def   , cat$unitarea*1000000.)  

# put river variables
ncvar_put(ncout, rivSlope_def  , riv$slope)  
ncvar_put(ncout, rivLength_def , riv$lengthkm*1000.)  
ncvar_put(ncout, rivDownId_def , riv$NextDownID)

# close the file, writing data to disk
nc_close(ncout)
