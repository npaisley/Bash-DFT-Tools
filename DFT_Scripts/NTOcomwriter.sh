#!/bin/bash

#use in for loops
#requires both .chk and .log from TDA calculation to be present
#reads the log file to find teh transition number corresponding to T1 and S1
#usage: ./<script>.sh <filename>.com
FILE=${1%.*}

RWF=$( grep %rwf ${FILE}.com )
RWF=${RWF%.rwf*}

CHK=$( grep %chk ${FILE}.com )
OLDCHK=${CHK#%chk*}
CHK=${CHK%.chk*}
for S in Singlet Triplet ; do
	STATE=($( grep -m1 ${S} ${FILE}.log ))
	STATE=${STATE[2]//:/}
	if [ "${S}" == "Singlet" ]; then
		END=S1
	else
		END=T1
	fi
	
cat > ${FILE}-NTO${END}.com << EOF
${RWF}-NTO${END}.rwf
%nosave
%oldchk${OLDCHK}
${CHK}-NTO${END}.chk
%mem=8GB
%nprocshared=16
# cam-b3lyp/6-31g(d) empiricaldispersion=gd3 Geom=Check Guess=(Read,Only) Density=(Check,Transition=${STATE}) Pop=(Minimal,NTO,SaveNTO)

${FILE} with cam-b3lyp/6-31g(d) empiricaldispersion=gd3 Geom=Check Guess=(Read,Only) Density=(Check,Transition=${STATE}) Pop=(Minimal,NTO,SaveNTO)

0 1


EOF
echo "${FILE}-NTO${END}.com written"

	done

exit 0
