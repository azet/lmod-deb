help( [[
The petsc module defines the following environment variables:
TACC_PETSC_DIR, TACC_PETSC_BIN, and
TACC_PETSC_LIB for the location
of the Petsc distribution, documentation, binaries,
and libraries.

Version 3.3; shared library support; hdf5 support; C++ support
external packages installed:  parmetis spai hypre   hdf5 mumps scalapack spooles superlu (sequential/distributed)
]] )

whatis( "Name: PETSc" )
whatis( "Version: 3.3; shared library support; hdf5 support; C++ support" )
whatis( "Version-notes: external packages installed:      --with-spai=1 --download-spai   --with-hdf5=1 --with-hdf5-dir=/opt/apps/intel13/mvapich2_1_9/phdf5/1.8.9 --with-hypre=1 --download-hypre        --with-mumps=1 --download-mumps   --with-scalapack=1 --download-scalapack     --with-blacs=1 --download-blacs   --with-spooles=1 --download-spooles   --with-superlu=1 --download-superlu   --with-superlu_dist=1 --download-superlu_dist     --with-parmetis=1 --download-parmetis --with-metis=1 --download-metis   " )
whatis( "Category: library, mathematics" )
whatis( "URL: http://www-unix.mcs.anl.gov/petsc/petsc-as/" )
whatis( "Description: Numerical library for sparse linear algebra" )

local             petsc_arch =    "sandybridge-cxxdebug"
local             petsc_dir =     "/opt/apps/intel13/mvapich2_1_9/petsc/3.3/"

prepend_path("PATH",            pathJoin(petsc_dir,petsc_arch,"bin") )
prepend_path("LD_LIBRARY_PATH", pathJoin(petsc_dir,petsc_arch,"lib") )

setenv("PETSC_ARCH",            petsc_arch)
setenv("PETSC_DIR",             petsc_dir)
setenv("TACC_PETSC_DIR",        petsc_dir)
setenv("TACC_PETSC_BIN",        pathJoin(petsc_dir,petsc_arch,"bin") )
setenv("TACC_PETSC_LIB",        pathJoin(petsc_dir,petsc_arch,"lib") )
