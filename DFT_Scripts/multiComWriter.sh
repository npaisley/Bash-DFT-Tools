#!/bin/bash
#script to write com files provided with xyz files (potentially basis set info as well)
#requires one argument
#can be run in for loops to do many files
#xyz coordinates and basis set are in input file

### Parameters ###
DFT_CALC=("SP" "opt freq") #calculations to run (ex. TD, TDA, opt, freq, opt freq, sp, etc.)
AB_CALC=("SP" "opt")
#AB_CALC=(${DFT_CALC[@]}) #uncomment this line and comment the one above to make AB and DFT calculations equivalent
AB_METHOD=("HF" "MP2") #ab initio methods
DFT_METHOD=("B3LYP" "LC-WHPBE" "CAM-B3LYP") #DFT methods (functionals)
DFT_ORBITAL_SYMMETRY=("R" "RO" "U") #list of orbital symmetries (ex. restricted (R), restricted open (RO), and unrestricted (U))
AB_ORBITAL_SYMMETRY=("R" "RO" "U")
#AB_ORBITAL_SYMMETRY=(${DFT_ORBITAL_SYMMETRY[@]}) #uncomment this line and comment the one above to make AB and DFT orbital symmetries equivalent
BASIS_SET=("6-31G(d)" "gen pseudo=read")
ROUTE_PARAMETERS=("scf=xqc" "geom=check guess=read")
DFT_CHARGE_MULTIPLICITY=("0 1" "0 3") #list charge and multiplicities here (ex. 0 1, 0 3, etc.)
AB_CHARGE_MULTIPLICITY=("0 1" "0 3") #list charge and multiplicities here (ex. 0 1, 0 3, etc.)
#AB_CHARGE_MULTIPLICITY=(${DFT_CHARGE_MULTIPLICITY[@]}) #uncomment this line and comment the one above to make AB and DFT charge and multiplicities equivalent
MEMORY="62GB" #total amount of memory needed and units.
CPUS="16" #number of cpus. 8 or 16 works well.
#example prameters
## fill out
######

usage (){
	echo "run using ./multiComWriter.sh <structure file.xyz>"
	echo
}

com_writer () {
# 1 full method
# 2 full route
# 3 charge and multiplicity
cat << EOF > "${FILE_NAME}"-"${C}"-"${FULL_METHOD}".com
%rwf=${FILE_NAME}-${1}.rwf
%nosave
%chk=${FILE_NAME}-${1}.chk
%mem=${MEMORY}
%nprocshared=${CPUS}
# ${3}

${FILE_NAME} (cm=${3}) with ${3}

${4}
$( cat ${FILE_NAME_FULL} )


EOF

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

#DFT com writing
if [[ -n ${DFT_CALC[1]} ]] ; then
	for C in ${DFT_CALC[@]} ; do
	for M in ${DFT_METHOD[@]} ; do
		for S in ${DFT_ORBITAL_SYMMETRY[@]} ; do
			for B in ${BASIS_SET[@]} ; do
				for R in ${ROUTE_PARAMETERS[@]} ; do
					for CM in ${DFT_CHARGE_MULTIPLICITY[@]} ; do
						FULL_ROUTE="${C} ${S}${M}/${B} ${R}"
						FULL_METHOD="${S}${M}"
						com_writer "${FULL_METHOD}" "${C}" "${FULL_ROUTE}" "${CM}"
					done
				done
			done
		done
	done
done
fi

#AB com writing
if [[ -n ${AB_CALC[1]} ]] ; then
	for C in ${AB_CALC[@]} ; do
	for M in ${AB_METHOD[@]} ; do
		for S in ${AB_ORBITAL_SYMMETRY[@]} ; do
			for B in ${BASIS_SET[@]} ; do
				for R in ${ROUTE_PARAMETERS[@]} ; do
					for CM in ${DFT_CHARGE_MULTIPLICITY[@]} ; do
						FULL_ROUTE="${C} ${S}${M}/${B} ${R}"
						FULL_METHOD="${S}${M}"
						com_writer "${FULL_METHOD}" "${FULL_ROUTE}" "${CM}"
					done
				done
			done
		done
	done
done
fi

exit 0
