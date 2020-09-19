#!/bin/bash

echo "File,S0 -> S1 (eV),f,S0 -> T1 (eV),f,deltaEst"
STATE_T=($( grep "Triplet" ${1} | head -n 1 ))
STATE_S=($( grep "Singlet" ${1} | head -n 1 ))

echo "$( basename ${1} ),${STATE_S[4]},${STATE_S[8]},${STATE_T[4]},${STATE_T[8]},$( echo "scale=10 ; ${STATE_S[4]} - ${STATE_T[4]}" | bc )"

exit 0
