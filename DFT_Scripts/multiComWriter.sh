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

### new version rewrite ###
# new version idea
# everything is based off a compound basename (aka. the structure being calculated)
# have a single route specified in the script (maybe in a text file but im not sure about this)
#	in addition to the route some simple things will also be held constant
#		charge and multiplicity
#		memory and num cpus
# additional info can be specified using a text file
# this will be controlled using getopts
# usage in teh form:
# ./multiComWriter.sh -n HMAT3TAZ -c "-TD" -o "-opt" -e
# in teh above case "HMAT3TAZ" is the base name. the oldchk file is to be included and is named "HMAT3TAZ-opt.chk"
# the new chk file is to be named "HMAT3TAZ-TD.chk"
# extra options are to be read from a file named "HMAT3TAZ.txt"
# this means that multiple com files can be generated (they will all have the same route aside from any additional information provided) when this is used in a loop
# in regards to oti type calculations this script would have to be used multiple times but that is an outside case. This script would match the usual workflow of DFT in our lab
# extra file would take the form
# xyz {
# data
# }
# basis {
# data
# }
# route {
# data
# }
# but the order would not matter

# get xyz data
# check if "xyz {" is present. a check for empty xyz data is done as well at the end
if grep -qE '[x,X][y,Y][z,Z][[:space:]]{0,}{' ${} ; then #add file #if "xyz {" present then attempt to read that data
	# check for multiple sets of xyz data. Error out if multiple found.
	if [[ $( grep -cE '[x,X][y,Y][z,Z][[:space:]]{0,}{' ) -gt 1 ]] ; then
		echo "multiple sets of xyz coordinates found. Specify only one."
		usage
		exit 1
	fi
	# Read XYZ values from additional file.
	# This is case and space insensitive aka. "xyz {" "XYZ{" "xYz  {" will all work. This is done to prevent issues with simple typos.
	XYZ_DATA_ST=$( grep -nE '[x,X][y,Y][z,Z][[:space:]]{0,}{' ${} | grep -oE '^[0-9]{1,}' ) #add file # get the line number that "xyz {" is on
	XYZ_DATA_END=$( tail -n +${XYZ_DATA_ST} ${} | grep -m 1 -nE '}' | grep -oE '^[0-9]{1,}' ) #add file # get the line number that the first "}" following "xyz {" is on 
	((XYZ_DATA_ST+=1)) #increment line number by one so "xyz {" line is ignored
	((XYZ_DATA_END-=2)) #decrease line number by one so the "}" line is ignored
	XYZ_DATA=$( tail -n +${XYZ_DATA_ST} ${} | head -n ${XYZ_DATA_END} | grep . ) #add file #assign the xyz data to the string XYZ_DATA adn remove any blank lines
else
	XYZ_DATA=NULL #set XYZ_DATA to null if "xyz {" is not present in the file
fi
XYZ_DATA=${XYZ_DATA:-NULL} #set XYZ_DATA to NULL if no xyz data is given but "xyz { }" is present. aka. the string is empty

# get basis data
# check if "basis {" is present. a check for empty basis data is done as well at the end
if grep -qE '[b,B][a,A][s,S][i,I][s,S][[:space:]]{0,}{' ${} ; then #add file #if "basis {" present then attempt to read that data
	# check for multiple sets of xyz data. Error out if multiple found.
	if [[ $( grep -cE '[b,B][a,A][s,S][i,I][s,S][[:space:]]{0,}{' ) -gt 1 ]] ; then
		echo "multiple sets of basis information found. Specify only one."
		usage
		exit 1
	fi
	# Read basis data from additional file.
	# This is case and space insensitive aka
	BASIS_DATA_ST=$( grep -nE '[b,B][a,A][s,S][i,I][s,S][[:space:]]{0,}{' ${} | grep -oE '^[0-9]{1,}' ) #add file # get the line number that "xyz {" is on
	BASIS_DATA_END=$( tail -n +${BASIS_DATA_ST} ${} | grep -m 1 -nE '}' | grep -oE '^[0-9]{1,}' ) #add file # get the line number that the first "}" following "basis {" is on 
	((BASIS_DATA_ST+=1)) #increment line number by one so "basis {" line is ignored
	((BASIS_DATA_END-=2)) #decrease line number by one so the "}" line is ignored
	BASIS_DATA=$( tail -n +${BASIS_DATA_ST} ${} | head -n ${BASIS_DATA_END} ) #add file #assign the basis data to a string
else
	BASIS_DATA=NULL #set to null if "basis {" is not present in the file
fi
BASIS_DATA=${BASIS_DATA:-NULL} #set to NULL if no basis data is given but "basis { }" is present. aka. the string is empty

# get additional route data
# check if "route {" is present. a check for empty route data is done as well at the end
if grep -qE '[r,R][o,O][u,U][t,T][e,E][[:space:]]{0,}{' ${} ; then #add file #if "route {" present then attempt to read that data
	# check for multiple sets of route data. Error out if multiple found.
	if [[ $( grep -cE '[r,R][o,O][u,U][t,T][e,E][[:space:]]{0,}{' ) -gt 1 ]] ; then
		echo "multiple sets of route information found. Specify only one."
		usage
		exit 1
	fi
	# Read route from file.
	# This is case and space insensitive
	ROUTE_DATA_ST=$( grep -nE '[r,R][o,O][u,U][t,T][e,E][[:space:]]{0,}{' ${} | grep -oE '^[0-9]{1,}' ) #add file # get the line number that "route {" is on
	ROUTE_DATA_END=$( tail -n +${XYZ_DATA_ST} ${} | grep -m 1 -nE '}' | grep -oE '^[0-9]{1,}' ) #add file # get the line number that the first "}" following "route {" is on 
	((XYZ_DATA_ST+=1)) #increment line number by one
	((XYZ_DATA_END-=2)) #decrease line number by one
	ROUTE_DATA=$( tail -n +${XYZ_DATA_ST} ${} | head -n ${XYZ_DATA_END} | xargs ) #add file #assign the data to a string and remove leading and trailing spaces Xargs also seems to remove new line characters so this will fix any issue where poeple add multiple lines of things in the route section. Or of course it could just mysteriously break teh whole script. Only time will tell
	
else
	ROUTE_DATA=NULL #set to null if "route {" is not present in the file
fi
ROUTE_DATA=${ROUTE_DATA:-NULL} #set to NULL if no route is given but "route { }" is present. aka. the string is empty

### end of rewrite ###





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
