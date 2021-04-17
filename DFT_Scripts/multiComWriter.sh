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
# imp: use printf -v ${1}_DATA "%s" "command or whatever" to set dynamic variable names. This will greatly simplify the script as the reading portion can become a function called with an argument that is the item to read. aka. xyz, route, basis. also use grep -i for cases insensitive search not regex...
# get xyz data
# check if "xyz {" is present. a check for empty xyz data is done as well at the end

file_reader () { #accepts two arguments. 1 is the search and variable keywod. 2 is the file.

if grep -iqE "${1}[[:space:]]{0,}{" ${2} ; then #if "keyword {" present then attempt to read that data. case insensitive.
	# check for multiple sets of data. Error out if multiple found.
	if [[ $( grep -icE "${1}[[:space:]]{0,}{" ) -gt 1 ]] ; then
		echo "multiple sets of ${1,,} data found. Specify only one." ## maybe make ${1} print in lower case using printf
		usage 
		exit 1
	fi
	# Read data.
	local DATA_ST=$( grep -inE "${1}[[:space:]]{0,}{" ${2} | grep -oE '^[0-9]{1,}' ) # get the line number that "keyword {" is on
	local DATA_END=$( tail -n +${DATA_ST} ${2} | grep -m 1 -nE '}' | grep -oE '^[0-9]{1,}' ) # get the line number that the first "}" following "keyword {" is on 
	((DATA_ST+=1)) #increment line number by one so "keyword {" line is ignored
	((DATA_END-=2)) #decrease line number by one so the "}" line is ignored
	if [[ ${DATA_END} -le 2 ]] ; then #set KEYWORD_DATA to NULL if no data is given but "keyword { }" or keyword { \n} is present. aka. no data is present
		printf -v "${1}_DATA" "%s" "NULL"
	fi
	printf -v "${1}_DATA" "%s" "$( tail -n +${DATA_ST} ${2} | head -n ${DATA_END} | grep . )" # assign the data to the string KEYWORD_DATA with any blank lines removed
fi

}

for KEYWORD in XYZ BASIS ROUTE ; do # add list elsewhere so it is easier to extend functionality 
	if $( grep -iqE "${KEYWORD}[[:space:]]{0,}{" ${} ) ; then #add file #if "keyword {" present then attempt to read that data. his is case and space insensitive ex. "xyz {" "XYZ{" "xYz  {" will all work. This is done to prevent issues with typos.
		file_reader "${KEYWORD}" "${}" #add file defined KEYWORD_DATA string
	else
		printf -v "${KEYWORD}_DATA" "%s" "NULL" # if keyword is not in the file set KEYWORD_DATA to NULL
	fi
done
# use to parse array tat will set where to look for what info
KEYWORD=(r route r cm m routeadd m xyz m basis r solvent) # r means route file. m means molecule file. these must be space separated and each keyword must be preceeded by a letter indicator so that teh script knows where to look for that data. these must also be in the order they are to be printed in the .com file as this list sets the order.
n=0
while [[ $n -lt ${#A[@]} ]] ; do
	if [[ ${A[$n]} == "r" ]] ; then
		((n++))
		echo "${A[$n]} is in the route file"
		((n++))
	elif [[ ${A[$n]} == "m" ]] ; then
		((n++))
		echo "${A[$n]} is in the molecule file"
		((n++))
	fi
done


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
