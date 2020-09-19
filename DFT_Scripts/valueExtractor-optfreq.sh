#!/bin/bash

HA_TO_EV=27.2114

HOMO=$( grep "Alpha  occ.*" ${1} | tail -n 1 )
HOMO=${HOMO##* }
HOMO=${HOMO// /}
HOMO_EV=$( echo "scale=10 ; ${HA_TO_EV} * ${HOMO}" | bc )

LUMO_LN=$( grep -n "Alpha  occ.*" ${1} | tail -n 1 )
LUMO_LN=${LUMO_LN%:*}
((LUMO_LN++))
LUMO=($( head -n ${LUMO_LN} ${1} | tail -n1 ))
LUMO_EV=$( echo "scale=10 ; ${HA_TO_EV} * ${LUMO[4]}" | bc )

DIPOLE_LN=$( grep -n " Electric dipole*" ${1} | tail -n 1 )
DIPOLE_LN=${DIPOLE_LN%: *}
DIPOLE_LN=$((DIPOLE_LN+3))
DIPOLE=($( head -n ${DIPOLE_LN} ${1}| tail -n 1 ))
DIPOLE=${DIPOLE[2]/D/E}

echo "File,HOMO (au),HOMO (eV),LUMO (au),LUMO (eV),Egap (eV),Dipole (Debye)"
echo "$( basename ${1} ),${HOMO},${HOMO_EV},${LUMO[4]},${LUMO_EV},$( echo "scale=10 ; ${LUMO_EV} - ${HOMO_EV}" | bc ),${DIPOLE}"

exit 0
