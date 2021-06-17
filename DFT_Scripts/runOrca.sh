#!/bin/bash
#SBATCH --cpus-per-task=16                # cpus, the nprocs defined in the input file (--ntasks=<nprocs> allows cpus to be on different nodes, --cpus-per-task=<nprocs> requires that all cpus be on teh same node)
#SBATCH --mem-per-cpu=3G           # memory per cpu in G (--mem=<mem>G is for total memory, --mem-per-cpu=<mem>G is mem per cpu [use when cpus on different nodes]). The memory that orca uses (specified on the %maxcore line in the inp file) should be no more than 75% of this amount.
#SBATCH --time=00-12:00            # calculation wall time (DD-HH:MM)
#SBATCH --mail-type=ALL            # email user when jobs starts, ends, fails, requeues, and on stage out
#SBATCH --mail-user=npaisley@chem.ubc.ca 
#SBATCH --export=JOBID=%j          # makes jobid a used variable

#submit this using: sbatch runOrca.sh

#input file name
### MAKE SURE YOU SET THIS ###
ORCA_INPUT="file.inp"
######

#output file header with some general information
printf '%s\nOrca calculation of %s\nNode: %s\nCalculation directory: \nCalculation Script: %s\nStarted on %s\n%s\n' "######" "${ORCA_INPUT}" "$( hostname )" "$( pwd )" "$( basename ${BASH_SOURCE} )" "$( date )" "######"

#load orca and required modules, Set MPI variables
module load StdEnv/2020  gcc/9.3.0  openmpi/4.0.3
module load orca/4.2.1
export OMPI_MCA_mtl='^mxm'
export OMPI_MCA_pml='^yalla'

#actually run orca
${EBROOTORCA}/orca "${ORCA_INPUT}" >> "${ORCA_INPUT%.inp}-${JOBID}.out"
CALC_EXIT=$?

printf '%s\nExit Orca Calculation of %s\nExit code: %s\nExit time: %s\n%s\n' "######" "${ORCA_INPUT}" "${CALC_EXIT}" "$( date )" "######"
exit ${CALC_EXIT}
