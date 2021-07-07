#!/bin/bash
#SBATCH --ntasks-per-node=16   # cpus, the nprocs defined in the input file (--ntasks=<nprocs> allows cpus to be on different nodes, --cpus-per-task=<nprocs> requires that all cpus be on the same node, --ntasks-per-node=<nprocs> is number of cpus per node if you specify the number of nodes you want)
#SBATCH --nodes=1    #number of nodes
#SBATCH --mem=251G           # memory per cpu in G (--mem=<mem>G is for total memory, --mem-per-cpu=<mem>G is mem per cpu [use when cpus on different nodes]). The memory that orca uses (specified on the %maxcore line in the inp file) should be no more than 75% of this amount.
#SBATCH --time=01-00:00            # calculation wall time (DD-HH:MM)
#SBATCH --mail-type=ALL            # email user when jobs starts, ends, fails, requeues, and on stage out
#SBATCH --mail-user=<email@email.com> #your email
#SBATCH --export=JOBID=%j          # makes jobid a usable variable
#SBATCH --export=ORCA_INPUT=<file>.inp # Input file name. *** IMP! set this ***
#SBATCH --output=<file>-%j.log       # output file for the calculation. *** IMP! set this ***

#submit this using: sbatch runOrca.sh

#output file header with some general information
printf 'Orca calculation of %s\nNode: %s\nCalculation directory: %s\nCalculation Script: %s\nStarted on %s\n' "${ORCA_INPUT}" "$( hostname )" "$( pwd )" "$( basename ${BASH_SOURCE} )" "$( date )"

#load orca and required modules, Set MPI variables
module load StdEnv/2020  gcc/9.3.0  openmpi/4.0.3
module load orca/4.2.1

#set openmpi paths
export PATH=/users/home/user/openmpi/bin:$PATH
export LD_LIBRARY_PATH=/users/home/user/openmpi/lib:$LD_LIBRARY_PATH
#set orca paths and communication protocols
export orcadir=/cvmfs/restricted.computecanada.ca/easybuild/software/2020/avx2/MPI/gcc9/openmpi4/orca/4.2.1/
export RSH_COMMAND="/usr/bin/ssh -x"
export PATH=/cvmfs/restricted.computecanada.ca/easybuild/software/2020/avx2/MPI/gcc9/openmpi4/orca/4.2.1/:$PATH
export LD_LIBRARY_PATH=/cvmfs/restricted.computecanada.ca/easybuild/software/2020/avx2/MPI/gcc9/openmpi4/orca/4.2.1/:$LD_LIBRARY_PATH
export OMPI_MCA_mtl='^mxm'
export OMPI_MCA_pml='^yalla'

#actually run orca using full path
${EBROOTORCA}/orca "${ORCA_INPUT}" >> "${ORCA_INPUT%.inp}.out"
CALC_EXIT=$?

printf 'Exit Orca Calculation of %s\nExit code: %s\nExit time: %s\n\n' "${ORCA_INPUT}" "${CALC_EXIT}" "$( date )"
exit ${CALC_EXIT}

