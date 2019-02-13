# Default GCC
#
# Config script for the linux environment at the Meteorological Institute Munich 08.Jan.2015
#
# and use this config file with `cmake <tenstream_root_dir> -DSYST:STRING=lmu_mim`

set(CMAKE_C_COMPILER   "mpiicc")
set(CMAKE_Fortran_COMPILER   "mpiifort")
set(Fortran_COMPILER_WRAPPER "mpiifort")

set(USER_C_FLAGS       "-Wall -std=c99 ")
set(USER_Fortran_FLAGS "-cpp -sox -no-wrap-margin")
set(USER_Fortran_FLAGS_RELEASE "-O3 -march=native -mtune=native -xHost -fp-model source -warn all ")
set(USER_Fortran_FLAGS_DEBUG "-traceback -extend_source -g -fp-model strict -ftrapuv -warn all -warn errors -fpe0 -O2 -g -check all -check nopointers -check noarg_temp_created ")

set(NETCDF_DIR      "$ENV{NETCDF}")
set(NETCDF_DIR_F90  "$ENV{NETCDF}")
