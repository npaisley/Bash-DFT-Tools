#!/bin/bash
#script to write com files provided with xyz files (potentially basis set info as well)
#requires one argument
#can be run in for loops to do many files
#xyz coordinates and basis set are in input file

### Parameters ###
DFT_CALC=("SP" "opt freq") #calculations to run (ex. TD, TDA, opt, freq, opt freq, sp, etc.)
AB_CALC=("SP")
#AB_CALC=(${DFT_CALC[@]}) #uncomment this line and comment the one above to make AB and DFT calculations equivalent
AB_METHOD=("HF" "MP2") #ab initio methods
DFT_METHOD=("B3LYP" "LC-WHPBE" "CAM-B3LYP") #DFT methods (functionals)
DFT_SPIN_TREATMENT=("R" "RO" "U") #list of spin treatments (ex. restricted (R), restricted open (RO), and unrestricted (U))
AB_SPIN_TREATMENT=("R" "RO" "U")
#AB_SPIN_TREATMENT=(${DFT_SPIN_TREATMENTS[@]}) #uncomment this line and comment the one above to make AB and DFT spin treatments equivalent
BASIS_SET=("6-31G(d)" "gen")
ROUTE_PARAMETERS=("pseudo=read scf=xqc" "geom=check guess=read")
DFT_CHARGE_MULTIPLICITY=("0 1" "0 3") #list charge and multiplicities here (ex. 0 1, 0 3, etc.)
AB_CHARGE_MULTIPLICITY=("0 1" "0 3") #list charge and multiplicities here (ex. 0 1, 0 3, etc.)
#AB_CHARGE_MULTIPLICITY=(${DFT_CHARGE_MULTIPLICITY[@]}) #uncomment this line and comment the one above to make AB and DFT charge and multiplicities equivalent
MEMORY="62GB" #total amount of memory needed and units.
CPUS="16" #number of cpus. 8 or 16 works well.
#example prameters
## fill out
######

com_writer () {
# $1 is the xyz file
# $2 is the method (theory) name
# $3 is the memory
# $4 is the cpus
# $5 is the route for that method
# $6 is the charge and multiplicity 

cat << EOF > "${1}"-"${2}".com
%rwf="${1}"-"${2}".rwf
%nosave
%chk="${1}"-"${2}".chk
%mem="${3}"
%nprocshared="${4}"
#"${5}"

"${1}" (cm="${6}") with "${5}"

"${6}"
$( cat ${FILE_NAME_FULL} )


EOF
}

usage (){
	echo "run using ./multiComWriter.sh <structure file.xyz>"
	echo
}

#make sure file name is provided. if it isnt then exit with an error message
if [[ -z ${1} ]] ; then
	echo "an xyz file must be specified"
	usage
	exit 1
fi

#assign xyz file name and name without the extension
FILE_NAME=${1%.*} #remove file extension
FILE_NAME_FULL=${1}

##completely rewrite
##have separate potrions for DFT and AB methods
#make route and write com file

#write DFT com files
#dft method
#spin




for CALC in ${DFT_CALC[@]} ; do
	for METHOD in ${DFT_METHOD[@]} ; do
		for SPIN in ${DFT_SPIN_TREATMENT[@]} ; do
			for BASIS in ${BASIS_SET[@]} ; do
				for ROU in ${ROUTE_PARAMETERS[@]} ; do
					for CM in ${DFT_CHARGE_MULTIPLICITY[@]} ; do
						FULL_ROUTE=" "
						METHOD=""
			

#assign charge and multiplicity and file name suffix according to method
for T in ${CALC_TYPE[@]} ; do
	if [[ ${T} == "SP" ]] ; then #do for all methods
		for S in ${SPIN_TREATMENT[@]} ; do
			for M in ${AB_METHODS[@]} ${DFT_METHODS[@]} ; do
				ROUTE=" ${T} ${S}${M}/gen pseudo=read scf=xqc"
				if [[ ${S} == "R" ]] ; then
					CHARGE_MULTIPLICITY="0 1"
				else
					CHARGE_MULTIPLICITY="0 3"
				fi
				METHOD_TYPE=${T}
				METHOD_NAME=${S}${M}
				com_writer "${FILE_NAME}" "${METHOD_TYPE}-${METHOD_NAME}" "${ROUTE}" "${CHARGE_MULTIPLICITY}"
			done
		done
	elif [[ ${T} == "TDA" ]] || [[ ${T} == "TD" ]] ; then #do for only DFT methods
		S="R" #only use restricted methods with TD and TDA
		for M in ${DFT_METHODS[@]} ; do
			ROUTE=" ${T}=${TDDFT_ROUTE} ${S}${M}/gen pseudo=read scf=xqc"
			#echo ${ROUTE} #for debugging
			CHARGE_MULTIPLICITY="0 1"
			METHOD_TYPE=${T}
			METHOD_NAME=${S}${M}
			com_writer "${FILE_NAME}" "${METHOD_TYPE}-${METHOD_NAME}" "${ROUTE}" "${CHARGE_MULTIPLICITY}"			
		done
	fi
done

exit 0
