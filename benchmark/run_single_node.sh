#!/bin/bash -e

EXE="$( pwd )/cp2k.psmp"

export CP2K_DATA_DIR=/scratch/santis/lucasbe/cp2k/cp2k-2.6/data/

for bench in H2O-hyb H2O-gga H2O-dftb dbcsr; do
    for processes in 1 2 4 8 16; do
        for threads in 1; do
            export OMP_NUM_THREADS=$threads
            #mpiexec -map-by core -bind-to core -n $processes \
            #     $EXE $bench.inp > $bench-$processes-$threads.out
            #
            srun --cpu_bind=verbose,cores --cpus-per-task=$threads --job-name=cp2k_$bench --nodes=1 --ntasks-per-node=$processes \
                 $EXE $bench.inp > $bench-$processes-$threads.out
        done
    done
done
