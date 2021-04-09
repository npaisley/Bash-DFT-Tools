#!/bin/bash
#SBATCH --mail-type=ALL      # email user when jobs starts, ends, fails, requeus, and on stage out (whatever that is)
#SBATCH --output=G16-RSHOpt-%j.out 

### Version ###
# Version: 0.9.1
# Date: 21 Mar 2019
# Written by: Nathan R. Paisley
# script for the optimization of w values in RSH DFT functionals with gaussian 16
# Can be submitted using the sg16submit-Mkx.x.x.sh script
######

### Starting bounds and convergence (tolerance) criteria ###
#For omega value in a.u. omega = W/10000. For convenience ALL w values in this script are used as omega*10000.
# These values can be adjusted to speed up calculations
W_LOWER=500
W_UPPER=5000
TOL=10
######

### Exit conditions and error checking ###
EXIT_CALCFAIL=1
EXIT_SPACES=2
EXIT_NOFILENAME=3
EXIT_FILEMISSING=4

#Make sure filename is given and contains no spaces. Assigns $1 as filename if present (for testing purposes).
COM_NAME=${1:-"$COM_NAME"}
if ( echo "${COM_NAME}" | grep -q " " ); then
	echo "ERROR: filename cannot contain spaces. Calculation cancelled"
	exit ${EXIT_SPACES}
fi
if [ -z ${COM_NAME} ]; then
	echo "ERROR: No filename specified"
	exit ${EXIT_NOFILENAME}
fi

#Make sure .com and .chk file are present
if [ ! -f ${COM_NAME}.com ] || [ ! -f ${COM_NAME}.chk ]; then
	echo "ERROR: .com or .chk file missing"
	exit ${EXIT_FILEMISSING}
fi

######

### Log file ###
LOG=${COM_NAME}-RSHOpt.log
######

#Load required modules and print header
module load gaussian/g16.b01
#Determine calculation start or restart and print to .out and .log files
if [ -f ${LOG} ]; then
	pwd; hostname
	echo >> ${LOG}
	echo "RSH functional optimization of ${COM_NAME} restarted on `date`" | tee -a ${LOG}
else
	pwd; hostname
	echo "RSH functional optimization of ${COM_NAME} started on `date`" | tee -a ${LOG}
fi

#format for J list
echo "Format: J2(w)=J2=(w, EHOMO(N), EHOMO(N+1), EGS(N-1), EGS(N), EGS(N+1))" | tee -a ${LOG}

### Functions ###
J2_calc () {
#Function to read required values from gaussian .log files and write them to the .log file. Takes w as an argument.
#Assign values for each variable in the calculation of J2(Y). 6 in total
#Order: w, EHOMO(N), EHOMO(N+1), EGS(N-1), EGS(N), EGS(N+1)

#Store w value as variable
JL_0=$1

#Find the last (aka. highest) occ. orbital energy value for the neutral species
#Store EHOMO(N) value as variable
JL_1_STR=$( grep "Alpha  occ." ${COM_NAME}-${1}-neutral.log | tail -n 1 )
JL_1_STR=${JL_1_STR%%+([[:space:]])}
JL_1_STR=${JL_1_STR##* }
JL_1=${JL_1_STR// /}

#Store EHOMO(N+1) value as variable. Looks at both alpha and beta orbitals and uses higher value
JL_2_STR_ALPHA=$( grep "Alpha  occ." ${COM_NAME}-${1}-anion.log | tail -n 1 )
JL_2_STR_ALPHA=${JL_2_STR_ALPHA%%+([[:space:]])}
JL_2_STR_ALPHA=${JL_2_STR_ALPHA##* }
JL_2_ALPHA=${JL_2_STR_ALPHA// /}

JL_2_STR_BETA=$( grep " Beta  occ." ${COM_NAME}-${1}-anion.log | tail -n 1 )
JL_2_STR_BETA=${JL_2_STR_BETA%%+([[:space:]])}
JL_2_STR_BETA=${JL_2_STR_BETA##* }
JL_2_BETA=${JL_2_STR_BETA// /}

if [ $(echo "${JL_2_ALPHA}>${JL_2_BETA}" | bc) -gt 0 ]; then 
	JL_2=${JL_2_ALPHA}
else 
	JL_2=${FL_2_BETA}
fi

#Find last SCF (ground state) energy and edit string to get energy value only
#Store EGS(N-1) value as variable
JL_3_STR=$( grep "SCF Done:" ${COM_NAME}-${1}-cation.log | tail -n 1 )
JL_3_STR=${JL_3_STR#*=}
JL_3_STR=${JL_3_STR%A.U.*}
JL_3=${JL_3_STR// /}

#Store EGS(N) value as variable
JL_4_STR=$( grep "SCF Done:" ${COM_NAME}-${1}-neutral.log | tail -n 1 )
JL_4_STR=${JL_4_STR#*=}
JL_4_STR=${JL_4_STR%A.U.*}
JL_4=${JL_4_STR// /}

#Store EGS(N+1) value as variable
JL_5_STR=$( grep "SCF Done:" ${COM_NAME}-${1}-anion.log | tail -n 1 )
JL_5_STR=${JL_5_STR#*=}
JL_5_STR=${JL_5_STR%A.U.*}
JL_5=${JL_5_STR// /}

#Calculate J2 and write all values to log file
J2=$(echo "scale=20;(((${JL_1})+(${JL_3})-(${JL_4}))^2)+(((${JL_2})+(${JL_4})-(${JL_5}))^2)" | bc)
echo "J2(${1})=${J2}=(${JL_0},${JL_1},${JL_2},${JL_3},${JL_4},${JL_5})" >> ${LOG}

}

Com_write () {
#Writes .com files for all charges at required w value. Takes w as an argument
COM_ROUTE=$( grep "^\#" ${COM_NAME}.com | head -n 1 )

#Convert W variable into 5 digit number (aka. add zero padding) for writing iop values and saves to new variable
printf -v COM_W "%05d" $1

#Set appropriate title, charge, and multiplicity
for CHARGE in cation neutral anion
do
	case $CHARGE in
		cation)
			COM_TITLE="sp calculation of ${COM_NAME} cation with w=${1}"
			COM_CRG_MULTI="1 2"
			;;
		neutral)
			COM_TITLE="sp calculation of ${COM_NAME} neutral with w=${1}"
			COM_CRG_MULTI="0 1"
			;;
		anion)
			COM_TITLE="sp calculation of ${COM_NAME} anion with w=${1}"
			COM_CRG_MULTI="-1 2"
			;;
	esac

cat > ${COM_NAME}-${W}-${CHARGE}.com << EOF
%oldchk=${COM_NAME}.chk
%chk=${COM_NAME}-${W}-${CHARGE}.chk
$( grep "%mem=" ${COM_NAME}.com )
$( grep "%nprocshared=" ${COM_NAME}.com )
${COM_ROUTE} geom=check guess=read iop(3/107=${COM_W}00000,3/108=${COM_W}00000)

${COM_TITLE}

${COM_CRG_MULTI}

EOF
	
	if grep -q "^\===EXTRA===" ${COM_NAME}.com; then
		COM_EXTRA=$( grep -n "^\===EXTRA===" ${COM_NAME}.com | cut -f1 -d:)
		COM_EXTRA=$((${COM_EXTRA}+1))
		tail -n +${COM_EXTRA} ${COM_NAME}.com >> ${COM_NAME}-${W}-${CHARGE}.com
		echo >> ${COM_NAME}-${W}-${CHARGE}.com
	fi
	
	echo >> ${COM_NAME}-${W}-${CHARGE}.com
	
done

}
######

#Calculate golden ratio
GR=$( echo "scale=20;(1+sqrt(5))/2" | bc )

#Assign initial W values and round them to nearest whole number
WL=${W_LOWER}
WU=${W_UPPER}
W1=$(echo "scale=20;${WU}-((${WU}-${WL})/${GR})" | bc )
printf -v W1 "%.*f" 0 $W1
W2=$(echo "scale=20;${WL}+((${WU}-${WL})/${GR})" | bc )
printf -v W2 "%.*f" 0 $W2

#Set iteration counter
ITER=0

#Perform iterative golden section search search until convergence condition is met. Values are reused where possible
while [ $((${WU}-${WL})) -gt ${TOL} ]
do
	ITER=$((ITER+1))
	echo >> ${LOG}
	echo "Iteration ${ITER}" >> ${LOG}
	echo "W1=${W1} and W2=${W2}" >> ${LOG}
	
	for W in ${W1} ${W2}
	do
		#Write com files for w values and perform sp calcs that have not already been computed successfully
		Com_write ${W}
		for CHARGE in neutral cation anion
		do
			if [ -f ${COM_NAME}-${W}-${CHARGE}.log ] && grep -q "Normal termination" ${COM_NAME}-${W}-${CHARGE}.log; then
				:
			else
				g16 <${COM_NAME}-${W}-${CHARGE}.com >${COM_NAME}-${W}-${CHARGE}.log
				EXIT=$?
				if [ ${EXIT} != 0 ]; then
					echo "calulation of ${COM_NAME}-${W}-${CHARGE} failed with exit code ${EXIT}"
					exit ${EXIT_CALCFAIL}
				fi
			fi
		done
		
		#Compute J2 values that have not already been calculated
		if grep -q "J2(${W})" ${LOG}; then
			:
		else
			J2_calc ${W}
		fi
	
	done
	
	#Get necessary J2 values
	#f(W1}=J21 and f(W2)=J22
	J21_STR=$( grep "J2(${W1})" ${LOG} | tail -n 1 )
	J21=${J21_STR#*=}
	J21=${J21%=*}
	J22_STR=$( grep "J2(${W2})" ${LOG} | tail -n 1 )
	J22=${J22_STR#*=}
	J22=${J22%=*}
	echo "J21=${J21} J22=${J22}" >> ${LOG}
	
	#GSS search. Reassign W values based upon corresponding J2 values
	if [ $(echo "${J21}<${J22}" | bc) -gt 0 ]; then 
		WU=${W2}
		W2=${W1}
		W1=$(echo "scale=20;${WU}-((${WU}-${WL})/${GR})" | bc )
		printf -v W1 "%.*f" 0 $W1
		echo "J21 less than J22" >> ${LOG}
		echo "New variables are: WL=${WL} W1=${W1} W2=${W2} WU=${WU}" >> ${LOG}
	else
		WL=${W1}
		W1=${W2}
		W2=$(echo "scale=20;${WL}+((${WU}-${WL})/${GR})" | bc )
		printf -v W2 "%.*f" 0 $W2
		echo "J21 greater than J22" >> ${LOG}
		echo "New variables are: WL=${WL} W1=${W1} W2=${W2} WU=${WU}" >> ${LOG}
	fi

done

#Calculate average W
WAVE=$( echo "((${WL}+${WU})/2)" | bc )
printf -v WAVE "%.*f" 0 $WAVE

#Output results to .log and .out file upon convergence
echo >> ${LOG}
echo "Optimization complete in ${ITER} iterations on `date`" | tee -a ${LOG}
echo "Final boundary conditions are: ${WL} and ${WU}" | tee -a ${LOG}
echo "Final W1 and W2 values are: ${W1} and ${W2}" | tee -a ${LOG}
echo "Average W value is ${WAVE}" | tee -a ${LOG}

exit 0

