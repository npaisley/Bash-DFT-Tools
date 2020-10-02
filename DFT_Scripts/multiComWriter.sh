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
DFT_SPIN_TREATMENT=("R" "RO" "U") #list of spin treatments (ex. restricted (R), restricted open (RO), and unrestricted (U))
AB_SPIN_TREATMENT=("R" "RO" "U")
#AB_SPIN_TREATMENT=(${DFT_SPIN_TREATMENTS[@]}) #uncomment this line and comment the one above to make AB and DFT spin treatments equivalent
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
#$1 xyz file
#$2 calc type
#$3 method
#$4 spin treatment
#$5 basis
#$6 route parameters
#$7 charge and multiplicity
#$8 memory
#$9 cpus




for CALC in ${2} ; do
	for METHOD in ${3} ; do
		for SPIN in ${4} ; do
			for BASIS in ${5} ; do
				for ROUTE in ${6} ; do
					for CM in ${7} ; do
						FULL_ROUTE="${CALC} ${SPIN}${METHOD}/${BASIS} ${ROUTE}"
						FULL_METHOD="${SPIN}${METHOD}"

cat << EOF > "${1}"-"${FULL_METHOD}".com
%rwf="${1}"-"${FULL_METHOD}".rwf
%nosave
%chk="${1}"-"${FULL_METHOD}".chk
%mem="${MEMORY}"
%nprocshared="${CPUS}"
#"${FULL_ROUTE}"

"${1}" (cm="${CM}") with "${FULL_ROUTE}"

"${CM}"
$( cat "${FILE_NAME_FULL}" )


EOF
					done
				done
			done
		done
	done
done
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

#DFT section
if [[ -n ${DFT_CALC[1]} ]] ; then
	com_writer "${FILE_NAME}" "(${DFT_CALC[@]})" "(${DFT_METHOD[@]})" "(${DFT_SPIN_TREATMENT[@]})" "(${BASIS_SET[@]})" "(${ROUTE_PARAMETERS[@]})" "(${DFT_CHARGE_MULTIPLICITY[@]})" "${MEMORY}" "${CPUS}"
fi

#ab section
if [[ -n ${AB_CALC[1]} ]] ; then
	com_writer "${FILE_NAME}" "${AB_CALC[@]}" "${AB_METHOD[@]}" "${AB_SPIN_TREATMENT[@]}" "${BASIS_SET[@]}" "${ROUTE_PARAMETERS[@]}" "${AB_CHARGE_MULTIPLICITY[@]}" "${MEMORY}" "${CPUS}"
fi

exit 0
