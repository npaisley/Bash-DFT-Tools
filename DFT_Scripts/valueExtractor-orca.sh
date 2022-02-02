#!/bin/bash
#this script extracts the homo, lumo, total energy, and first singlet and triplet excited state energies from orca calculations
#2022, Nathan R. Paisley

usage () {
	echo "run with: ./<script>.sh <orca output file>.log <ouput summary file name>.csv"
	echo "An output csv file is optional. If left unspecified the script will output results to the command line."
	echo "run in a for loop when analysing many calculations."
	echo "The header is only printed when it is not present in the specified output file (doesn't work with output redirection)"
	echo
}

#variables
HA_TO_EV=27.2114
HEADER="File,HOMO (au),HOMO (eV),LUMO (au),LUMO (eV),Egap (eV),Energy (au),S0 -> S1 (eV),S0 -> S2 (eV),S0 -> S3 (eV),S0 -> S4 (eV),S0 -> T1 (eV),S0 -> T2 (eV),S0 -> T3 (eV),S0 -> T4 (eV),deltaEst"

#check if $1 has been given. If it hasn't then explain the error, give the proper usage, and exit with status 1
if [[ -z "${1}" ]] ; then
	echo "No file name provided. Please provide a file to analyze"
	echo
	usage
	exit 1
fi

#find the HOMO and LUMO energy and assign lines to arrays
#HOMO is ${HOMO_LINE[2]} in Ha and ${HOMO_LINE[3]} in eV
#LUMO is ${LUMO_LINE[2]} in Ha and ${LUMO_LINE[3]} in eV

ORBITAL_ENERGY_LINE_NUMBER=$( grep -ni 'orbital energies' ${1} | grep -oE '^[0-9]{1,}' )
HOMO_LINE=($( tail -n +${ORBITAL_ENERGY_LINE_NUMBER} ${1} | grep -Em 1 -B 1 '^[[:space:]]{1,}[0-9]{1,}[[:space:]]{1,}0.0000' | head -n 1 ))
LUMO_LINE=($( tail -n +${ORBITAL_ENERGY_LINE_NUMBER} ${1} | grep -Em 1 '^[[:space:]]{1,}[0-9]{1,}[[:space:]]{1,}0.0000' ))

#calculate the HOMO LUMO gap
EGAP=$( echo "scale=10 ; ${LUMO_LINE[3]} - ${HOMO_LINE[3]}" | bc )

#find the total energy of the molecule in Ha. ${TOTAL_ENERGY_LINE[4]}
TOTAL_ENERGY_LINE=($( grep -i 'final single point energy' ${1} ))

#get singlet and triplet excited state information or state that they haven't been calculated

if grep -qi 'TD-DFT/TDA EXCITED STATES (SINGLETS)' "${1}"; then
	SINGLET_LINE_NUMBER=$( grep -in 'TD-DFT/TDA EXCITED STATES (SINGLETS)' ${1} | grep -oE '^[0-9]{1,}' )
	# energy in Ha is [3] in eV is [5]
	SINGLET1=($( tail -n +${SINGLET_LINE_NUMBER} ${1} | grep -m 1 -Ei "state[[:space:]]{1,}1:" ))
	SINGLET2=($( tail -n +${SINGLET_LINE_NUMBER} ${1} | grep -m 1 -Ei "state[[:space:]]{1,}2:" ))
	SINGLET3=($( tail -n +${SINGLET_LINE_NUMBER} ${1} | grep -m 1 -Ei "state[[:space:]]{1,}3:" ))
	SINGLET4=($( tail -n +${SINGLET_LINE_NUMBER} ${1} | grep -m 1 -Ei "state[[:space:]]{1,}4:" ))	
else
	SINGLET1[3]="Not calculated"
	SINGLET2[3]="Not calculated"
	SINGLET1[5]="Not calculated"
	SINGLET2[5]="Not calculated"
	DELTAEST="Not calculated"
fi

if grep -qi 'TD-DFT/TDA EXCITED STATES (TRIPLETS)' "${1}"; then
	TRIPLET_LINE_NUMBER=$( grep -in 'TD-DFT/TDA EXCITED STATES (TRIPLETS)' ${1} | grep -oE '^[0-9]{1,}' )
	# energy in Ha is [3] in eV is [5]
	TRIPLET1=($( tail -n +${TRIPLET_LINE_NUMBER} ${1} | grep -m 1 -Ei "state[[:space:]]{1,}1:" ))
	TRIPLET2=($( tail -n +${TRIPLET_LINE_NUMBER} ${1} | grep -m 1 -Ei "state[[:space:]]{1,}2:" ))
	TRIPLET3=($( tail -n +${TRIPLET_LINE_NUMBER} ${1} | grep -m 1 -Ei "state[[:space:]]{1,}3:" ))
	TRIPLET4=($( tail -n +${TRIPLET_LINE_NUMBER} ${1} | grep -m 1 -Ei "state[[:space:]]{1,}4:" ))	
else
	TRIPLET1[3]="Not calculated"
	TRIPLET2[3]="Not calculated"
	TRIPLET1[5]="Not calculated"
	TRIPLET2[5]="Not calculated"
	DELTAEST="Not calculated"
fi

DELTAEST=$( echo "scale=10 ; ${SINGLET1[5]} - ${TRIPLET1[5]}" | bc )


#output results to file or command line
if [[ -n "${2}" ]] ; then
	if [[ ! -f "${2}" ]] ; then
		touch "${2}"
	fi
	if grep -q "${HEADER}" "${2}" ; then
		echo "$( basename "${1}" ),${HOMO_LINE[2]},${HOMO_LINE[3]},${LUMO_LINE[2]},${HOMO_LINE[3]},${EGAP},${TOTAL_ENERGY_LINE[4]},${SINGLET1[5]},${SINGLET2[5]},${SINGLET3[5]},${SINGLET4[5]},${TRIPLET1[5]},${TRIPLET1[5]},${TRIPLET3[5]},${TRIPLET4[5]},${DELTAEST}" >> "${2}"
	else
		echo "${HEADER}" >> "${2}"
		echo "$( basename "${1}" ),${HOMO_LINE[2]},${HOMO_LINE[3]},${LUMO_LINE[2]},${HOMO_LINE[3]},${EGAP},${TOTAL_ENERGY_LINE[4]},${SINGLET1[5]},${SINGLET2[5]},${SINGLET3[5]},${SINGLET4[5]},${TRIPLET1[5]},${TRIPLET1[5]},${TRIPLET3[5]},${TRIPLET4[5]},${DELTAEST}" >> "${2}"
	fi
else
	echo "${HEADER}"
	echo "$( basename "${1}" ),${HOMO_LINE[2]},${HOMO_LINE[3]},${LUMO_LINE[2]},${HOMO_LINE[3]},${EGAP},${TOTAL_ENERGY_LINE[4]},${SINGLET1[5]},${SINGLET2[5]},${SINGLET3[5]},${SINGLET4[5]},${TRIPLET1[5]},${TRIPLET1[5]},${TRIPLET3[5]},${TRIPLET4[5]},${DELTAEST}"
fi

exit 0
