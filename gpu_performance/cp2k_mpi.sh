#!/bin/sh

set -e

#
# number of GPUs with compute_capability >=3.5
#
NGPUS=1

#
# start an MPS server instance for each GPU
#
for ((i=0; i< ${NGPUS}; i++)); do
    export CUDA_VISIBLE_DEVICES=${i}
    export CUDA_MPS_PIPE_DIRECTORY=/tmp/mps_${i}
    export CUDA_MPS_LOG_DIRECTORY=/tmp/mps_log_${i}
    mkdir -p ${CUDA_MPS_PIPE_DIRECTORY}
    mkdir -p ${CUDA_MPS_LOG_DIRECTORY}
    nvidia-cuda-mps-control -d
done

#
# launch the application
#
export OMP_NUM_THREADS=1
mpiexec --n 4 cp2k.psmp H2O-32.inp > cp2k_mpi.out
