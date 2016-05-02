#!/bin/sh

set -e

export OMP_NUM_THREADS=1
mpiexec --n 4 cp2k.psmp H2O-32.inp > cp2k_mpi.out
