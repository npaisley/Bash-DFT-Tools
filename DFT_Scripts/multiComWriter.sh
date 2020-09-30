#!/bin/bash
#script to write com files provided with xyz files (potentially basis set info as well)
#requires one argument
#can be run in for loops to do many files
#xyz coordinates and basis set are in input file
## add usage function and print when no file name given

### Parameters ###
## organize this section better
## add example parameters section
ROUTE="pseudo=read scf=xqc"
BASIS_SET=("6-31G(d)" "gen")
DFT_CALC=("SP" "TDA=(50-50,nstates=10)" "TD=(50-50,nstates=10)") #calculations to run (ex. TD, TDA, opt, freq, opt freq, sp, etc.)
AB_CALC=("SP")
#AB_CALC=(${DFT_CALC[@]}) #uncomment this line and comment the one above to make AB and DFT calculations equivalent
DFT_SPIN_TREATMENT=("R" "RO" "U") #list of spin treatments (ex. restricted (R), restricted open (RO), and unrestricted (U))
AB_SPIN_TREATMENT=("R" "RO" "U")
#AB_SPIN_TREATMENT=(${DFT_SPIN_TREATMENTS[@]}) #uncomment this line and comment the one above to make AB and DFT spin treatments equivalent
AB_METHODS=("HF" "MP2") #ab initio methods
DFT_METHODS=("B3LYP" "LC-WHPBE" "CAM-B3LYP") #DFT methods (functionals)
DFT_CHARGE_MULTIPLICITY=("0 1" "0 3") #list charge and multiplicities here (ex. 0 1, 0 3, etc.)
AB_CHARGE_MULTIPLICITY=("0 1" "0 3") #list charge and multiplicities here (ex. 0 1, 0 3, etc.)
#AB_CHARGE_MULTIPLICITY=(${DFT_CHARGE_MULTIPLICITY[@]}) #uncomment this line and comment the one above to make AB and DFT charge and multiplicities equivalent
######

com_writer () {
# $1 is the xyz file
# $2 is the method name
# $3 is the route for that method
# $4 is the charge and multiplicity 

cat << EOF > ${1}-${2}.com
%rwf=${1}-${2}.rwf
%nosave
%chk=${1}-${2}.chk
%mem=62GB
%nprocshared=16
#${3}

${1} (cm=${4}) with ${3}

${4}
$( cat ${FILE_NAME_FULL} )


EOF
}

#make sure file name is provided. if it isnt then exit with an error message
if [[ -z ${1} ]] ; then
	echo "an xyz file must be specified"
	exit 1
fi

#assign full xyz file name and name without the extension
FILE_NAME=${1%.*} #remove file extension
FILE_NAME_FULL=${1}

##completely rewrite
##have separate potrions for DFT and AB methods
#make route and write com file

#assign charge and multiplicity and file name suffix according to method
for T in ${CALC_TYPE[@]} ; do
	if [[ ${T} == "SP" ]] ; then #do for all methods
		for S in ${SPIN_TREATMENT[@]} ; do
			for M in ${AB_METHODS[@]} ${DFT_METHODS[@]} ; do
				ROUTE=" ${T} ${S}${M}/gen pseudo=read scf=xqc"
				#echo ${ROUTE} #for debugging
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
