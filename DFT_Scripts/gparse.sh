#!/bin/bash
#parsing utility for gaussian log files containing two-electron integrals
#scf=conventional will print these (NOTE: the files are extremely large! aka. many GB)
#use: ./<script> <file>.log

START_OVR=$( egrep -n -m 1 '[*]{1,}.Overlap.[*]{1,}' ${1} | egrep -o '^[0-9]{1,}' ) # find line number where overlap integrals start

START_KE=$( egrep -n -m 1 '[*]{1,}.Kinetic.Energy.[*]{1,}' ${1} | egrep -o '^[0-9]{1,}' ) #find line number where kinetic energy integrals start. Also functions as end of overlap integrals
END_KE=$( egrep -n -m 2 '^ Entering.OneElI\.\.\.' ${1} | egrep -o '^[0-9]{1,}' | tail -n 1 ) # Entering oneElI... occurs serveral times in the log file. The second one ends to KE section so get only that one

START_PE=$( egrep -n -m 1 '[*]{1,}.Potential.Energy.[*]{1,}' ${1} | egrep -o '^[0-9]{1,}' )
END_PE=$( egrep -n -m 1 '[*]{1,}.Core.Hamiltonian.[*]{1,}' ${1} | egrep -o '^[0-9]{1,}' )

START_TEINT=$( egrep -in -m 1 'dumping two-electron integrals' ${1} | egrep -o '^[0-9]{1,}' ) #get the line number which the 2e integral section starts at
TEINT_NUM=$( egrep -o -m 1 'ITotal=[^a-Z]{1,}' ${1} | egrep -o '[0-9]{1,}' ) # get the total number of integrals
END_TEINT=$( echo "7 + ${TEINT_NUM} + ${START_TEINT}" | bc ) #7 lines after the dumping two-electron integrls line the actual integrals start

csplit -s ${1}  ${START_OVR} ${START_KE} ${END_KE} ${START_PE} ${END_PE} ${START_TEINT} ${END_TEINT} #split file before and after overlap, KE, PE, and 2eint section
mv xx01 ${1}.overlapint #rename overlap integral file
mv xx02 ${1}.keint #rename kinetic energy file
mv xx04 ${1}.peint #rename potential energy file
mv xx06 ${1}.twoeint #rename 2eint file

cat xx0[3,5,7] >> xx00 #remake log file without extracted data
mv xx00 ${1}.corpse #rename parsed log file
rm xx0* #clean up unneeded file

exit 0
