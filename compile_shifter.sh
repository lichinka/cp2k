#!/bin/sh

SRC_DIR="$( pwd )/cp2k-2.6"

#
# checkout the lastest source from the 2.6 branch
#
svn checkout http://svn.code.sf.net/p/cp2k/code/branches/cp2k-2_6-branch cp2k-src
mv cp2k-src/cp2k ${SRC_DIR}
rm -rf cp2k-src

##
## module setup for CP2K
##
#if [ -z "$( module list 2>&1 | grep PrgEnv-gnu )" ]; then
#    module switch PrgEnv-cray PrgEnv-gnu
#fi
#module load fftw
#module load cudatoolkit
#module load cray-libsci

#
# arch file
#
ARCH_NAME="CRAY-XC30-gfortran-cuda-custom"
ARCH_VERS="psmp"

cat > ${SRC_DIR}/arch/${ARCH_NAME}.${ARCH_VERS} <<EOF
# Program environments:
# - module load PrgEnv-gnu ; module load fftw ; module load cudatoolkit ; module load cray-libsci
NVCC     = nvcc -D__GNUC_MINOR__=6 -D__GNUC__=4
CC       = cc
CPP      =   
FC       = ftn 
LD       = ftn 
AR       = ar -r
CPPFLAGS =
DFLAGS   = -D__FFTW3 -D__parallel -D__SCALAPACK -D__HAS_smm_dnn -D__ACC -D__DBCSR_ACC -D__PW_CUDA
CFLAGS   = \$(DFLAGS) -fopenmp -fno-omit-frame-pointer -O3 -ffast-math
FCFLAGS  = \$(DFLAGS) -fopenmp -mavx -funroll-loops -ffast-math -ftree-vectorize -ffree-form -ffree-line-length-512 -fno-omit-frame-pointer -std=f2003 -fimplicit-none -Werror=aliasing -Werror=ampersand -Werror=c-binding-type -Werror=intrinsic-shadow -Werror=intrinsics-std -Werror=line-truncation -Werror=tabs -Werror=realloc-lhs-all -Werror=target-lifetime -Werror=underflow -Werror=unused-but-set-variable -Werror=unused-variable -Werror=conversion -Wno-use-no-only -Wzerotrip
LDFLAGS  = \$(FCFLAGS)
NVFLAGS  = \$(DFLAGS) -arch sm_35
LIBS     = -lfftw3 -lfftw3_threads -lcudart -lcufft -lcublas -lrt
LIBS    += ${SRC_DIR}/../libsmm_dnn_cray.gnu.a
EOF

#
# compile
#
cd ${SRC_DIR}/makefiles
make -j 4 ARCH=${ARCH_NAME} VERSION=${ARCH_VERS} && \
echo "You may find the executables in <${SRC_DIR}/exe>"
