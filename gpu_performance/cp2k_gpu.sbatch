#!/bin/bash -l
#
#========================================
# DESCRIPTION (APPLICATION SPECIFIC)
#========================================
# The script runs a water box to test the performance of CP2K
# The output and log file will be saved ...
#
# Input files:
#  GTH_BASIS_SETS
#  H2O-256.inp
#  POTENTIAL
# 
# Output file:
#  $outdir/$SLURM_JOB_ID.out
#
# Log file for perfomance:
#  $logdir/$SLURM_JOB_ID.log
#========================================
# SLURM VARIABLES (APPLICATION SPECIFIC)
#========================================
#SBATCH --job-name="cp2k_gpu"
#SBATCH --time=00:30:00
#SBATCH --nodes=4
#SBATCH --ntasks-per-core=1
#SBATCH --ntasks-per-node=2
#SBATCH --cpus-per-task=4
#===================================
# SETUP (GENERAL)
#===================================
cdate=$(date "+%d-%m-%Y_%H-%M-%S");
# check if logdir is defined
if [ -z $logdir ]; then
 logdir=$SLURM_SUBMIT_DIR;
fi
# check if outdir is defined
if [ -z $outdir ]; then
 outdir=$SLURM_SUBMIT_DIR;
fi
# check if machine is defined
if [ -z $machine ]; then
 machine=$(echo $HOSTNAME | sed 's/[0-9]*//g');
fi
# output file
out="$SLURM_JOB_NAME.out";
# logfile with history of performance
log="$logdir/$SLURM_JOB_NAME.log";
# check if logfile exists and if it is group readable and writeable
if [ ! -f "$log" ]; then
 echo "# wall-time, performance (day/ns) and % performance difference on $SLURM_JOB_NUM_NODES nodes, $SLURM_NTASKS_PER_NODE MPI tasks per node" > $log;
# make the newly created $log file group readable and writeable
 chmod g+rw $log;
elif [ ! -r "$log" ]; then
# echo an error if $log file is not group readable and exit
 echo -e "$machine $cdate $SLURM_JOB_ID \t ERROR: log file $log is not group readable!" >> /dev/stderr;
 exit 1;
elif [ ! -w "$log" ]; then
# echo an error if $log file is not group writeable and exit
 echo -e "$machine $cdate $SLURM_JOB_ID \t ERROR: log file $log is not group writeable!" >> /dev/stderr;
 exit 1;
fi
# SLURM variables
SLURM_NTASKS=$[$SLURM_NTASKS_PER_NODE*$SLURM_JOB_NUM_NODES];
echo -e "\nRunning on $machine (job ID $SLURM_JOB_ID)";
echo -e "Log file      : $log";
echo -e "Output folder : $outdir";
echo -e "$SLURM_JOB_NUM_NODES nodes, $SLURM_NTASKS_PER_NODE tasks per node ($SLURM_TASKS_PER_NODE), $SLURM_CPUS_PER_TASK cpus per task, $SLURM_NTASKS total tasks\n";
#========================================
# RUN AND CHECK (APPLICATION SPECIFIC)
#========================================
# load modules and run simulation
#module swap PrgEnv-cray PrgEnv-gnu;
module load cudatoolkit;
module load fftw;
export CRAY_CUDA_MPS=1;
EXE="./cp2k.psmp";
#aprun -n $SLURM_NTASKS -N $SLURM_NTASKS_PER_NODE -d $SLURM_CPUS_PER_TASK $EXE H2O-256.inp > "$out";
srun -N $SLURM_JOB_NUM_NODES --ntasks-per-node=$SLURM_NTASKS_PER_NODE -c $SLURM_CPUS_PER_TASK $EXE H2O-256.inp > "$out";

#========================================
# check output file
steps=$(grep "STEP NUM" $out |wc -l);
if [[ "$steps" -ne "10" ]]
then
 echo -e "$machine $cdate $SLURM_JOB_ID \t Job output NOT OK: test FAILED!" >> "$log";
 exit 1;
fi
#========================================
# summary of results: new time (s)
new=$(grep " CP2K   " $out | awk '{print $7}');
# reference time (s), performance difference (%)
if [ -f "$reffile" ]; then
 ref=$(grep -v '#' $reffile | grep $machine | tail -1 | sed 's/Time\=//' | awk '{printf"%.3lf\n", $(NF-1)}');
 if [ -n "$ref" ]; then
  delta=$(printf '%.3lf\n' $(echo "(1-$new/$ref)*100" | bc -l));
 else
  delta=0;
 fi
else
 delta=0;
fi
# print results on log file
echo -e "$machine $cdate $SLURM_JOB_ID \t Time=$new Difference=$delta%" >> "$log";
#========================================
# COPY OUTPUT (GENERAL)
#========================================
# copy output and log files to outdir
store="$SLURM_JOB_NAME-$SLURM_JOB_ID.out";
chmod g+rw $out;
cp -p $out $outdir/$store;
exit 0;
#========================================
