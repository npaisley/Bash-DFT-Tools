#!/bin/bash
#this script extracts the homo, lumo, total energy, and first singlet and triplet excited state energies from Gaussian calculations

usage () {
	echo "run with: ./<script>.sh <log file>.log >> <file name>.csv"
	echo ">> <file name>.csv is used to append output to a file that can be opened with excel"
	echo "run in a for loop when analysing many calculations"
}

#conversions factors
HA_TO_EV=27.2114

#number of excited states to get information about
NUMBER_STATES=1


#check is $1 has been given. If it hasn't then explain the error, give teh proper usage, and exit with status 1
if ! [[ -n "${1}" ]] ; then
	echo "no file name provided"
	echo "please provide a file to analyze"
	usage
	exit 1
fi

#find the HOMO energy by searching for the last line with Alpha  occ. in it and taking the last string in the line
HOMO=$( grep -Eio 'Alpha[[:space:]]{1,}occ.*' ${1} | tail -n 1 | grep -Eio '[^[:space:]]$' )
HOMO_EV=$( echo "scale=10 ; ${HA_TO_EV} * ${HOMO}" | bc )

#find the LUMO energy by searching for teh last line with Alpha  occ. and taking the line below it. Parse this line so that the first number used
LUMO=$( grep -A 1 -Ei '^[[:space:]]{1,}Alpha[[:space:]]{1,}occ.' | tail -n 1 | grep -Eio '^([[:space:]]|)([a-Z]|[[:space:]]|\.)*--([[:space:]]|-)*([0-9]|\.)*' | grep -Eio '[^[:space]]{1,}$' )
LUMO_EV=$( echo "scale=10 ; ${HA_TO_EV} * ${LUMO}" | bc )

#get the electric dipole if it is present
if grep -qi 'electric dipole' ${1}  ; then
	DIPOLE=($( grep -A 3 -Ei 'electric dipole' ${1} | tail -n 1 ))
	DIPOLE=${DIPOLE[2]/D/E}
else
	DIPOLE='not found'
fi

#find the total energy of the molecule and get the method used (this a convienent time to get this information)
if grep -qi 'eump[0-9]' ${1} ; then
	TOTAL_ENERGY=$( grep -Eio 'eump[0-9]' | tail -n 1 | grep -Eo '[^[:space]]{1,}$' )
	TOTAL_ENERGY=${TOTAL_ENERGY/D/E}
	METHOD="$( grep -Eio 'E\((RO|R|U)HF\)' | grep -Eio '(RO|R|U)' )$( grep -Eio 'eump[0-9]' ${1} | tail -n 1 | grep -Eoi 'mp[0-9]' )"
else
	TOTAL_ENERGY_STRING=$( grep -Eio 'E\(([a-Z]|[0-9]|-)*\)[[:space:]]{1,}-([0-9]|\.)*' ${1} | tail -n 1 )
	TOTAL_ENERGY=$( echo ${TOTAL_ENERGY_STRING} | grep -Eo '[^[:space]]{1,}$'  )
	METHOD=$( echo ${TOTAL_ENERGY_STRING} | grep -Eo '^[^[:space]]{1,}')
fi

#get excited state information
#deteermine if excited state info present
#then get excited state info 
if grep -qi 'excitation energies and oscillator strengths:' ; then
	SINGLET=($( grep -m 1 -Ei "excited state.{1,}singlet" ${1} ))
	TRIPLET=($( grep -m 1 -Ei "excited state.{1,}triplet" ${1} ))
else
	SINGLET='Not calculated'
	TRIPLET='Not calculated'
fi	

echo "File,Method,HOMO (au),HOMO (eV),LUMO (au),LUMO (eV),Egap (eV),Dipole (Debye),Energy (au),S0 -> S1 (eV),f,S0 -> T1 (eV),f,deltaEst"
echo "$( basename ${1} ),${HOMO},${HOMO_EV},${LUMO[4]},${LUMO_EV},$( echo "scale=10 ; ${LUMO_EV} - ${HOMO_EV}" | bc ),${DIPOLE},${SINGLET[4]},${SINGLET[8]},${TRIPLET[4]},${TRIPLET[8]},$( echo "scale=10 ; ${SINGLET[4]} - ${TRIPLET[4]}" | bc )"

exit 0
