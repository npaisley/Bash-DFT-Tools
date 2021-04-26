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

file_reader () { #accepts two arguments. 1 is the item keyword. 2 is the file name.

local DATA_ST=$( grep -in "<${1}>" ${2} | grep -oE '^[^:]{1,}' ) # get the line number that "<keyword>" is on
local DATA_END=$( grep -in "</${1}>" ${2} | grep -oE '^[^:]{1,}' ) # get the line number that "</keyword>" is on
if [[ $(( DATA_END - DATA_ST )) -le 1 ]] || [[ $( tail -n +$(( DATA_ST + 1 )) ${2} | head -n $(( DATA_END - DATA_ST - 1 )) | grep -cE '[^[:blank:]]' ) -eq 0 ]] ; then # set KEYWORD_DATA to NULL if keyword tags are present but there is no data or if the keyword tags are in the wrong order.
	printf -v "${1}_DATA" "%s" "NULL"
	printf "No $s data found or tags are miss ordered in file %s. %s data set to NULL and will not be added to output files\n" "${1,,}" "${2}" "${1,,}" # print message informing user if keyword data is set to NULL
else
	printf -v "${1}_DATA" "%s" "$( tail -n +$(( DATA_ST + 1 )) ${2} | head -n $(( DATA_END - DATA_ST - 1 )) )" # assign the data to the string KEYWORD_DATA
	printf "%s data found" "${1,,}" # inform user keyword data found
fi

}

# Below is the array that controls the entire script. If you mess it up you will break the script!!
# The order of these strings is very important for multiple reasons
# This makes the script dynamic and allows you to add new sections that you want written in bulk with ease.
# You can add or remove items as long as you follow the directions below
# this requires that you add a pair of items to the below array AND then add the section to the appropriate file (calculation or molecule) with proper tags
#     Regarding the array: 
#         Use calc to tell the script the item is in the calculation file. This should be done if the item is specific to the calculation NOT the molecule. These itmes will be included in every calculation type
#         Use mol to tell the script the item is in the molecule file. This should be used for items that are molecule specific NOT calculation specific. These items will be included in every file for that molecule
#         The order of these pairs is crucial as it sets the order that they are printed in the ouput .com files. If you put in the wrong order you will generate files that gaussian can't read.
#         The items must be space separated (so DO NOT use itmes with spaces in their names! You WILL BREAK SHIT) and each data keyword MUST be preceeded by an indicator (calc or mol) so that the script knows where to look for that data.
#         The strings must be preceeded by "KEYWORD=(" and followed by ")" (google "bash arrays" if you are curious why)
#     Regarding the tags:
#         The header is <keyword> and the footer is </keyword> and they must be in the appropriate file. If is is in the wrong file it will be ignored.
#         This is case insensitive but EVERYHTING ELSE MUST BE EXACT. aka is you use < keyword> or forget the / it will NOT WORK.
KEYWORD=(calc ROUTE calc CM mol ROUTEADD mol XYZ mol BASIS calc SOLVENT) 

# parse the KEYWORD array to deermine where to find what data and then set that data to appropriate strings
for (( INDEX = 0 ; INDEX < "${#KEYWORD[@]}" ; INDEX += 2 )) ; do
	#use this to parse array and find the relavent data
	if [[ "${KEYWORD[$INDEX]}" -eq "calc" ]] ; then
		
		#look in calc file
		
	elif [[ "${KEYWORD[$INDEX]}" -eq "mol" ]] ; then
		if $( grep -iqE "<${KEYWORD}>" ${} ) && $( grep -iqE "</${KEYWORD}>" ${} ) ; then #add file #if "<keyword>" and "</keyword>" present then attempt to read that data. this is case insensitive ex. "<xyz>" "<XYZ>" "<xYz>" will all work. This is done to prevent issues with typos.
			if [[ $( grep -ic "<${KEYWORD}>" ${} ) -gt 1 ]] || [[ $( grep -ic "</${KEYWORD}>" ${} ) -gt 1 ]] ; then
				printf -v "${KEYWORD}_DATA" "%s" "NULL" # if too many tags are present set KEYWORD_DATA to NULL and notify the user
				printf "Multiple start or end tags for %s data is present in file %s. %s data set to NULL and will not be added to output files\n" "${KEYWORD,,}" "${}" "${KEYWORD,,}" # add file # print error message saying one or both tags are missing. Continue script though, this is just to inform the user incase they want that data. 
			fi
			file_reader "${KEYWORD}" "${}" #add file # define KEYWORD_DATA string
		else
			printf -v "${KEYWORD}_DATA" "%s" "NULL" # if keyword is not in the file set KEYWORD_DATA to NULL
			printf "Either one or both tags for %s data is missing from file %s. %s data set to NULL and will not be added to output files\n" "${KEYWORD,,}" "${}" "${KEYWORD,,}" # add file # print error message saying one or both tags are missing. Continue script though, this is just to inform the user incase they want that data.
		fi
	else
		printf "ERROR: KEYWORD array in script file contains file keywords besides calc and mol"
		exit 1 # change this error code to something useful
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
