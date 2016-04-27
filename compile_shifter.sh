#!/bin/sh

set -e

SRC_DIR="$( pwd )/cp2k-2.6"
SMM_LIB="libsmm_dnn_linux.gnu.custom.a"

#
# checkout the lastest source from the 2.6 branch
#
if [ ! -d "${SRC_DIR}" ]; then
	svn checkout http://svn.code.sf.net/p/cp2k/code/branches/cp2k-2_6-branch cp2k-src
	mv cp2k-src/cp2k ${SRC_DIR}
fi

#
# module setup
#
case $( hostname ) in
    *greina*)
        MODS="cuda70/toolkit/7.0.28 cuda70/blas/7.0.28 cuda70/fft/7.0.28"
        ;;
    *)
	MODS=""
        echo "WARNING: not loading modules."
        ;;
esac
echo "Checking modules on $( hostname ) ..."
for m in ${MODS}; do
    if [ -z "$( echo ${LOADEDMODULES} | grep ${m} )" ]; then
        echo -e "Missing <${m}>"
        exit 1
    fi
done

#
# build the libsmm - takes a long time
#
SMM_CONFIG="config/linux.gnu.custom"

if [ ! -f "${SMM_LIB}" ]; then
	cd ${SRC_DIR}/tools/build_libsmm
	#
	# create a configuration file to build on a single node (i.e. no SLURM)
	#
	cat > config/none.wlm <<EOF
batch_cmd() {
    \$@;
}
EOF
	#
	# customize the host compilation
	#
	cat > ${SMM_CONFIG} <<EOF
#
# target compiler... these are the options used for building the library.
# They should be aggessive enough to e.g. perform vectorization for the specific CPU (e.g. -ftree-vectorize -march=native),
# and allow some flexibility in reordering floating point expressions (-ffast-math).
# Higher level optimisation (in particular loop nest optimization) should not be used.
#
target_compile="gfortran -O2 -funroll-loops -ffast-math -ftree-vectorize -march=native -cpp -finline-functions -fopenmp"

#
# target dgemm link options... these are the options needed to link blas (e.g. -lblas)
# blas is used as a fall back option for sizes not included in the library or in those cases where it is faster
# the same blas library should thus also be used when libsmm is linked.
#
blas_linking="-lblas"

#
# host compiler... this is used only to compile a few tools needed to build
# the library. The library itself is not compiled this way.
# This compiler needs to be able to deal with some Fortran2008 constructs.
#
host_compile="gfortran -O2 -std=f2008"
EOF
	#
	# build
	#
	./generate clean
	./generate -c ${SMM_CONFIG} -j 2 -t 16 -w none tiny1
	./generate -c ${SMM_CONFIG} tiny2
	./generate -c ${SMM_CONFIG} -j 2 -t 16 -w none small1
	./generate -c ${SMM_CONFIG} small2
	./generate -c ${SMM_CONFIG} -j 2 -t 16 -w none lib
	./generate -c ${SMM_CONFIG} -j 2 -t 16 -w none check1
	cp lib/${SMM_LIB} ${SRC_DIR}/..
	cd ${SRC_DIR}/..
fi

#
# arch file
#
ARCH_NAME="Linux-x86-64-gfortran-cuda-custom"
ARCH_VERS="psmp"

cat > ${SRC_DIR}/arch/${ARCH_NAME}.${ARCH_VERS} <<EOF
# 
# OpenMP+MPI+CUDA version with double precision support
#
NVCC     = nvcc -D__GNUC_MINOR__=6 -D__GNUC__=4
CC       = gcc
CPP      = g++ 
FC       = gfortran 
LD       = gfortran
AR       = ar -r
CPPFLAGS =
DFLAGS   = -D__FFTW3 -D__parallel -D__SCALAPACK -D__HAS_smm_dnn -D__ACC -D__DBCSR_ACC -D__PW_CUDA
CFLAGS   = \$(DFLAGS) -fopenmp -fno-omit-frame-pointer -O3 -ffast-math
FCFLAGS  = \$(DFLAGS) -fopenmp -mavx -funroll-loops -ffast-math -ftree-vectorize -ffree-form -ffree-line-length-512 -fno-omit-frame-pointer -std=f2003 -fimplicit-none -Werror=aliasing -Werror=ampersand -Werror=c-binding-type -Werror=intrinsic-shadow -Werror=intrinsics-std -Werror=line-truncation -Werror=tabs -Werror=realloc-lhs-all -Werror=target-lifetime -Werror=underflow -Werror=unused-but-set-variable -Werror=unused-variable -Werror=conversion -Wno-use-no-only -Wzerotrip
LDFLAGS  = \$(FCFLAGS)
NVFLAGS  = \$(DFLAGS) -arch sm_35
LIBS     = -lfftw3 -lfftw3_threads -lcudart -lcufft -lcublas -lrt
LIBS    += ${SRC_DIR}/../${SMM_LIB}
EOF

#
# compile
#
cd ${SRC_DIR}/makefiles
make -j 4 ARCH=${ARCH_NAME} VERSION=${ARCH_VERS} && \
echo "You may find the executables in <${SRC_DIR}/exe>"
