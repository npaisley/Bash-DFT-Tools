#!/bin/bash
#this script extracts the homo, lumo, total energy, and first singlet and triplet excited state energies from Gaussian calculations
#2020, Nathan R. Paisley

usage () {
	echo "run with: ./<script>.sh <log file>.log <ouput file name>.csv"
	echo "An output file is optional. If left unspecified the script will output results to the command line."
	echo "run in a for loop when analysing many calculations."
	echo "The header is only printed when it is not present in the specified output file (doesn't work with output redirection)"
	echo
}

#variables
HA_TO_EV=27.2114
HEADER="File,Method,HOMO (au),HOMO (eV),LUMO (au),LUMO (eV),Egap (eV),Dipole (Debye),Energy (au),S0 -> S1 (eV),f,S0 -> T1 (eV),f,deltaEst"

#check is $1 has been given. If it hasn't then explain the error, give the proper usage, and exit with status 1
if [[ -z "${1}" ]] ; then
	echo "No file name provided. Please provide a file to analyze"
	echo
	usage
	exit 1
fi

#find the HOMO energy by searching for the last line with Alpha  occ. in it and taking the last string in the line
HOMO=$( grep -Eio 'Alpha[[:space:]]{1,}occ.*' "${1}" | tail -n 1 | grep -Eio '[^[:space:]]{1,}$' )
if [[ -n ${HOMO} ]] ; then
	HOMO_EV=$( echo "scale=10 ; ${HA_TO_EV} * ${HOMO}" | bc )
else
	HOMO="not calculated"
	HOMO_EV="not calculated"
fi

#find the LUMO energy by searching for the last line with Alpha  occ. and taking the line below it. Parse this line so that the first number used
LUMO=$( grep -A 1 -Ei '^[[:space:]]{1,}Alpha[[:space:]]{1,}occ.' "${1}" | tail -n 1 | grep -Eio '^([[:space:]]|)([a-Z]|[[:space:]]|\.)*--([[:space:]]|-)*([0-9]|\.)*' | grep -Eio '[^[:space:]]{1,}$' )
if [[ -n ${LUMO} ]] ; then
	LUMO_EV=$( echo "scale=10 ; ${HA_TO_EV} * ${LUMO}" | bc )
else
	LUMO="not calculated"
	LUMO_EV="not calculated"
fi
	
#calculate the HOMO LUMO gap
if [[ ${LUMO} != "not calculated" ]] && [[ ${HOMO} != "not calculated" ]] ; then
	EGAP=$( echo "scale=10 ; ${LUMO_EV} - ${HOMO_EV}" | bc )
else
	EGAP="not calculated"
fi

#get the electric dipole if it is present
if grep -qi 'electric dipole' "${1}"  ; then
	DIPOLE_STRING=($( grep -A 3 -Ei 'electric dipole' "${1}" | tail -n 1 ))
	DIPOLE=${DIPOLE_STRING[2]/D/E}
else
	DIPOLE='Not Calculated'
fi

#find the total energy of the molecule and get the method used (this a convienent time to get this information)
if grep -qi 'eump[0-9]' "${1}" ; then
	TOTAL_ENERGY=$( grep -Eio 'eump[0-9][[:space:]]{1,}=[[:space:]]{1,}([0-9]|-|D|\+|\.)*' "${1}" | tail -n 1 | grep -Eo '[^[:space:]]{1,}$' )
	TOTAL_ENERGY=${TOTAL_ENERGY/D/E}
	METHOD="$( grep -Eio 'E\((RO|R|U)HF\)' "${1}" | grep -Eio '(RO|R|U)' | tr -d '\n' )$( grep -Eio 'eump[0-9]' "${1}" | tail -n 1 | grep -Eoi 'mp[0-9]' )"
else
	TOTAL_ENERGY_STRING=$( grep -Eio 'E\(([a-Z]|[0-9]|-)*\)[[:space:]]{1,}=[[:space:]]{1,}-([0-9]|\.){1,}*' "${1}" | tail -n 1 )
	TOTAL_ENERGY=$( echo "${TOTAL_ENERGY_STRING}" | grep -Eo '[^[:space:]]{1,}$'  )
	METHOD=$( echo "${TOTAL_ENERGY_STRING}" | grep -Eo '^[^[:space:]]{1,}')
fi

#get singlet and triplet excited state information or state that they haven't been calculated
if grep -qi 'excitation energies and oscillator strengths:' "${1}"; then
	SINGLET=($( grep -m 1 -Ei "excited state.{1,}singlet" "${1}" ))
	TRIPLET=($( grep -m 1 -Ei "excited state.{1,}triplet" "${1}" ))
	DELTAEST=$( echo "scale=10 ; ${SINGLET[4]} - ${TRIPLET[4]}" | bc )
else
	SINGLET[4]="Not calculated"
	SINGLET[8]="Not calculated"
	TRIPLET[4]="Not calculated"
	TRIPLET[8]="Not calculated"
	DELTAEST="Not calculated"
fi	

#output results to file or command line
if [[ -n "${2}" ]] ; then
	if [[ ! -f "${2}" ]] ; then
		touch "${2}"
	fi
	if grep -q "${HEADER}" "${2}" ; then
		echo "$( basename "${1}" ),${METHOD},${HOMO},${HOMO_EV},${LUMO},${LUMO_EV},${EGAP},${DIPOLE},${TOTAL_ENERGY},${SINGLET[4]},${SINGLET[8]},${TRIPLET[4]},${TRIPLET[8]},${DELTAEST}" >> "${2}"
	else
		echo "${HEADER}" >> "${2}"
		echo "$( basename "${1}" ),${METHOD},${HOMO},${HOMO_EV},${LUMO},${LUMO_EV},${EGAP},${DIPOLE},${TOTAL_ENERGY},${SINGLET[4]},${SINGLET[8]},${TRIPLET[4]},${TRIPLET[8]},${DELTAEST}" >> "${2}"
	fi
else
	echo "${HEADER}"
	echo "$( basename "${1}" ),${METHOD},${HOMO},${HOMO_EV},${LUMO},${LUMO_EV},${EGAP},${DIPOLE},${TOTAL_ENERGY},${SINGLET[4]},${SINGLET[8]},${TRIPLET[4]},${TRIPLET[8]},${DELTAEST}"
fi

exit 0
