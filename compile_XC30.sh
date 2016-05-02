#!/bin/sh

SRC_DIR="$( pwd )/cp2k-2.6"

if [ ! -d "${SRC_DIR}" ]; then
    #
    # checkout the latest source from the 2.6 branch
    #
    svn checkout http://svn.code.sf.net/p/cp2k/code/branches/cp2k-2_6-branch cp2k-src
    mv cp2k-src/cp2k ${SRC_DIR}
    rm -rf cp2k-src
fi
echo "Using CP2K source at <${SRC_DIR}> ..."

#
# module setup for CP2K - Santis
#
if [ -z "$( module list 2>&1 | grep PrgEnv-gnu )" ]; then
    module switch PrgEnv-cray PrgEnv-gnu
fi
module load fftw
module load cudatoolkit
module load cray-libsci

#
# libint compilation
#
LIBINT_DIR=${SRC_DIR}/tools/hfx_tools/libint_tools

if [ ! -f "${LIBINT_DIR}/lib/libint.a" ]; then
    cd ${LIBINT_DIR}/tools/hfx_tools/libint_tools
    wget http://sourceforge.net/projects/libint/files/v1-releases/libint-1.1.4.tar.gz/download
    tar xvzf libint-1.1.4.tar.gz
    cd libint-1.1.4
    ./configure --prefix=${LIBINT_DIR}
    make clean
    make -j 4
    make install
fi
LIBINT_DIR=${LIBINT_DIR}/lib
echo "Using LibInt binary at <${LIBINT_DIR}> ..."

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
DFLAGS   = -D__FFTW3 -D__parallel -D__SCALAPACK -D__HAS_smm_dnn -D__LIBINT -D__ACC -D__DBCSR_ACC -D__PW_CUDA
CFLAGS   = \$(DFLAGS) -fopenmp -fno-omit-frame-pointer -O3 -ffast-math
FCFLAGS  = \$(DFLAGS) -fopenmp -mavx -funroll-loops -ffast-math -ftree-vectorize -ffree-form -ffree-line-length-512 -fno-omit-frame-pointer -std=f2003 -fimplicit-none -Werror=aliasing -Werror=ampersand -Werror=c-binding-type -Werror=intrinsic-shadow -Werror=intrinsics-std -Werror=line-truncation -Werror=tabs -Werror=realloc-lhs-all -Werror=target-lifetime -Werror=underflow -Werror=unused-but-set-variable -Werror=unused-variable -Werror=conversion -Wno-use-no-only -Wzerotrip
LDFLAGS  = \$(FCFLAGS)
NVFLAGS  = \$(DFLAGS) -arch sm_35
LIBS     = -lfftw3 -lfftw3_threads -lcudart -lcufft -lcublas -lrt
LIBS    += ${SRC_DIR}/../libsmm_dnn_cray.gnu.a
LIBS    += ${LIBINT_DIR}/libderiv.a ${LIBINT_DIR}/libint.a ${LIBINT_DIR}/libr12.a
EOF

#
# compile
#
cd ${SRC_DIR}/makefiles
make -j 4 ARCH=${ARCH_NAME} VERSION=${ARCH_VERS} && \
echo "CP2K binaries created in <${SRC_DIR}/exe/${ARCH_NAME}>"
