#!/bin/sh

set -e

##
## start an MPS server instance for one GPU
##
#export CUDA_VISIBLE_DEVICES=0
#nvidia-smi -i 0 -c EXCLUSIVE_PROCESS
#nvidia-cuda-mps-control -d

#
# check the CUDA MPS environment is set up
#
if [ -z "$( nvidia-smi -q -d compute | grep -i 'compute mode' | grep -i 'Exclusive_Process' )" ]; then
    echo "No GPU found in EXCLUSIVE_PROCESS mode. Exiting."
    exit 1
fi

#
# launch the application
#
export OMP_NUM_THREADS=1
mpiexec --n 4 cp2k.psmp H2O-32.inp > cp2k_mpi.out
