# Config script for the linux environment on Cirrus at HU Berlin with Intel compiler
#
# and use this config file with `cmake <tenstream_root_dir> -DSYST:STRING=lmu_mim`

set(CMAKE_C_COMPILER   "mpiicc")
set(CMAKE_Fortran_COMPILER   "mpiifort")
set(Fortran_COMPILER_WRAPPER "mpiifort")

set(USER_C_FLAGS       "-Wall -std=c99")
set(USER_Fortran_FLAGS "-g -cpp -sox -no-wrap-margin -mkl=sequential -warn all")
set(USER_Fortran_FLAGS_RELEASE "-xCORE-AVX2 -march=native -Ofast -ftz -pc64 -fp-model fast=2 -no-prec-div -no-prec-sqrt -fast-transcendentals")
set(USER_Fortran_FLAGS_DEBUG "-traceback -extend_source -g -fp-model strict -ftrapuv -warn all -warn errors -fpe0 -O2 -g -check all -check nopointers -check noarg_temp_created ")

set(NETCDF_DIR      "/nfsusr/usr_intel_2019_update5/")
set(NETCDF_DIR_F90  "/nfsusr/usr_intel_2019_update5/")
set(PETSC_DIR       "/nfsusr/usr_intel_2019_update5/petsc_3.12.2_double/")
