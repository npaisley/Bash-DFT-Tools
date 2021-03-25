#!/bin/bash

### NOTES ###
# Version: 0.9.3.x
# Written by: Nathan R. Paisley.
# April 29, 2019
#
# Script to make submitting jobs easier and make long jobs easier to deal with
#
# DO NOT change any values in this script!
# Memory and number of CPUs are read from your com file. 
# The walltime is preset and can be changed by using the respective script option.
# Your email is set and changed by using the script.
# If the default script is used calculations can be set to before they timeout (5 min before)
# Alternative scripts can be used but requeuing is disabled
# requeing is also disabled for TD-DFT and TDA-DFT since # restart does not work with those methods
#
# To Do:
# enable requeuing for RSHopt
# add command option to print last x number of submitted jobs (filename jobid)
# improve formatting of text sent to log fle (on going)
# Write all log output to temp file (use TEMP=$( mktemp )) and then write to log all at once (https://unix.stackexchange.com/questions/181937/how-create-a-temporary-file-in-shell-script)
# recognize what kind of calculation has been run and if the job completes summarize important info (ex. if structure if converged for opt and freq)
######

### STUFF ###
SCRIPT_CALC=G16Calc-1.7.4.sh
LOG_DIR=~/sg16log
LOG=${LOG_DIR}/sg16submit.log 
COMP_VALUE=2 # this value is added to the memory requested in the com file to account for gaussian over use of memory. Value in GB. Gaussian typically uses about 1 GB more than specified.
SCRIPT_NAME=$( basename $BASH_SOURCE )
SCRIPT_FULLNAME=$( realpath $BASH_SOURCE )
GAUSSIAN_VERSION=
######

# this should be moved
# gaussian version check
if $( module spider gaussian | grep -q g16.c01 ) ; then 
	echo "version exists"
else 
	echo "version not found"
fi

#gaussian version latest
#im honestly not sure what I was trying to do here
G=$( module spider gaussian | grep "gaussian/" | tail -n 2 | head -n 1 )  && G=${G// /}
available versions
V=$( module spider gaussian | grep gaussian/ ) 
VL=$( echo "$V" | wc -l ) 
echo "$V" | head -n $(( ${VL} - 1 )) 

### EXIT CONDITIONS ###
ER_COM_FILE=1
ER_TIME_FORMAT=2
ER_SCRIPT_ALT=3
ER_COM_FORMAT=4
ER_MEM_UNIT=5
ER_SPACES=6
ER_EMAIL=7
ER_WALLTIME=8
ER_LOG_FILE=9
ER_RESTART=10
ER_SUB_FAIL=11
ER_GAUSSIAN_ACCESS=12
######

### Functions ###
usage () { 
# read current email
EMAIL=$( grep '#EMAIL=' ${LOG} )
EMAIL=${EMAIL#*=}
EMAIL=${EMAIL:-"none set"}
# read current default walltime
WALLTIME=$( grep \#WALLTIME= ${LOG} )
WALLTIME=${WALLTIME#*=}

echo
echo " Usage: ${SCRIPT_NAME} -f <file.com> [-t <dd-hh:mm>] [-s <script>] [-r] [-h] [-T] [-E]"
echo
echo " Current email: ${EMAIL} | Current walltime: ${WALLTIME}"
echo
echo " -f | designates the .com file to be used"
echo " -t | gives a temporary, non-default, walltime to use"
echo " -s | calls for an alternative script to be used"
echo " -r | requests that the calculation be set to requeue itself upon timeout. This only works with the default script"
echo " -h | displays this help"
echo " -T | changes the default time"
echo " -E | changes the email notifications are sent to"
echo
echo " -f is the only required argument"
echo
exit 0
}

script_write () {
cat << 'EOF' > ${SCRIPT_CALC} #use of quotes stops parameter expansion in heredoc
#!/bin/bash
#SBATCH --mail-type=ALL # email user when jobs starts, ends, fails, requeues, and on stage out

SCRIPT_NAME=$( basename $BASH_SOURCE )

echo "<calculation>"
echo
echo "directory: $( pwd )"
echo "node: $( hostname )"
echo "script: ${SCRIPT_NAME}"
echo
echo "Gaussian 16 calculation of: ${COM_NAME}"

module load gaussian/g16.b01

echo "started on: $( date )"
timeout ${TIMEOUT}m g16 < ${COM_NAME}.com >> ${COM_NAME}.log             # g16 command
CALC_EXIT=$?
echo "finished with exit code ${CALC_EXIT} on: $( date )"
echo

if [ "${CALC_EXIT}" -eq 124 ] || [ "${CALC_EXIT}" = 128+9 ]; then
	if [ "${RESTART}" = "TRUE" ]; then
		echo "Walltime reached"
		echo "Rewriting com file and resubmitting" #rewrite .com file without oldchk (if it is present) and with # restart as route and requeue
		sed -i '/^%oldchk=/Id' ${COM_NAME}.com
		sed -i 's/^# .*/# restart/' ${COM_NAME}.com
		
		echo >> ${LOG}
		echo "<submission>" >> ${LOG}
		echo "	type: resubmission" >> ${LOG}
		echo "	script: ${SCRIPT_NAME}" >> ${LOG}
		echo "	time: $( date )" >> ${LOG}
		echo "	file: $( realpath ${COM_NAME}.com )" >> ${LOG}
		echo "	command: sbatch --mail-user=${EMAIL} --time=${TIME} --mem=${MEM_VAL}${MEM_UNIT} --cpus-per-task=${NCPUS} --output=${COM_NAME}-%j.out --export=COM_NAME=${COM_NAME},EMAIL=${EMAIL},TIME=${TIME},MEM_VAL=${MEM_VAL},MEM_UNIT=${MEM_UNIT},NCPUS=${NCPUS},SCRIPT=${SCRIPT},TIMEOUT=${TIMEOUT},RESTART=${RESTART},LOG=${LOG} ${SCRIPT}" | tee -a ${LOG}
		sbatch --mail-user=${EMAIL} --time=${TIME} --mem=${MEM_VAL}${MEM_UNIT} --cpus-per-task=${NCPUS} --output=${COM_NAME}-%j.out --export=COM_NAME=${COM_NAME},EMAIL=${EMAIL},TIME=${TIME},MEM_VAL=${MEM_VAL},MEM_UNIT=${MEM_UNIT},NCPUS=${NCPUS},SCRIPT=${SCRIPT},TIMEOUT=${TIMEOUT},RESTART=${RESTART},LOG=${LOG} ${SCRIPT} | tee -a ${LOG}
		SUB_EXIT=$?
		echo "</submission>" >> ${LOG}
		if [ ! "${SUB_EXIT}" -eq 0 ]; then
			echo "ERROR: submission unsuccessful"
			exit 66
		fi
		exit 77
	elseif [ "${CALC_EXIT}" -eq 0 ]
		#check for NImag if a frequency calculation has been run last
		#some if statment so this is only done when a freq calc is run
		#can probably be implemented by passing information from the com reader in the submit script
		NIMAG=$( cat ${COM_NAME}.log | tr -d '\n' | tr -d ' ' | grep -ioE "NImag=[0-9]{1,}" | tail -n 1 ) #get NImag string
		NIMAG_NUM=${NIMAG#*=} #extract only the number from NImag
		echo >> ${LOG}
		echo "<calculation>" >> ${LOG}
		echo "	type: completion" >> ${LOG}
		echo "	script: ${SCRIPT_NAME}" >> ${LOG}
		echo "	time: $( date )" >> ${LOG}
		echo "	file: $( realpath ${COM_NAME}.com )" >> ${LOG}
		echo "	exit code: ${CALC_EXIT}" >> ${LOG}
		echo "</calculation>" >> ${LOG}
	else
		echo >> ${LOG}
		echo "<calculation>" >> ${LOG}
		echo "	type: error" >> ${LOG}
		echo "	script: ${SCRIPT_NAME}" >> ${LOG}
		echo "	time: $( date )" >> ${LOG}
		echo "	file: $( realpath ${COM_NAME}.com )" >> ${LOG}
		echo "	exit code: ${CALC_EXIT}" >> ${LOG}
		echo "</calculation>" >> ${LOG}
fi

echo "</calculation>"

exit ${CALC_EXIT}

EOF
}

com_read () {
# requires COM_FULLNAME as argument. If a keyword is repeated then only the top one is used
# should be followed by error check (see if error is set to true)
# read all required values from com file
# oldchk memory cpus route 
# add error checking at end. memory (val and units) cpus chk route and rwf must be specified

# check to make sure required values are present
for I in %rwf= %chk= %mem= %nprocshared= ; do
	if ! grep -iq "${I}" ${COM_FULLNAME}; then
		echo "ERROR: ${I} missing from .com file"
		ERROR=TRUE
	fi
done

# get rwf file name
RWF_FULLNAME=$( grep -i %rwf= ${1} | head -n 1 )
RWF_FULLNAME=${RWF_FULLNAME##*=}

# get chk file name
CHK_FULLNAME=$( grep -i %chk= ${1} | head -n 1 )
CHK_FULLNAME=${CHK_FULLNAME##*=}

# get oldchk file name
if ! grep -qi %oldchk= ${1} ; then
	OLDCHK_FULLNAME=$( grep -i %oldchk= ${1} | head -n 1 )
	OLDCHK_FULLNAME=${OLDCHK_FULLNAME##*=}
fi

# get memory amount and unit
COM_MEM=$( grep %mem= ${1} | head -n 1 )
COM_MEM=${COM_MEM##*=}
MEM_VAL=${MEM//[!0-9]/}
MEM_UNIT=${MEM//[!M,G]/}

# get cpus amount
NCPUS=$( grep -i %nprocshared= ${1} | head -n 1 )
NCPUS=${NCPUS//[!0-9]/}

# route stuff. will have to think over this
ROUTE=$( grep \# ${1} | head -n 1 )

# use below for error checking. Rest is not needed
	echo "ERROR: incorrect memory units specified in .com file. Must use MB or GB"
	exit ${ER_MEM_UNIT}
}

log_write () {
mkdir ${LOG_DIR}
touch ${LOG}
cat > ${LOG} <<EOF 
Log File for ${SCRIPT_NAME}

### Default Values ###
#EMAIL=
#WALLTIME=01-00:00
#GAUSSIAN_VERSION=
######

EOF
}

email_write () {
# get user to input new email
echo -n "Enter the email you would like to use: "
read EMAIL_NEW
while : ; do
	echo
	echo -e "Notifications will be sent to" "\e[4m${EMAIL_NEW}\e[0m"
	echo -n "Is this correct? [y/n]: "
	read EMAIL_CONF
	case ${EMAIL_CONF} in
		y|Y|yes)
			break
			;;
		n)
			echo "email unchanged"
			exit ${ER_EMAIL}
			;;
		*)
			echo
			echo "please select y or n"
			;;
	esac
done

# write email to the log file
sed -i 's/^#EMAIL=.*/#EMAIL='"${EMAIL_NEW}"'/' ${LOG}
echo "email set"
echo
}

walltime_write () {
# get user to input new walltime
echo
echo -n "Enter the walltime you would like to use (format is dd-hh:mm): "
read TIME_NEW
if [[ ! ${TIME_NEW} =~ ^[0-9]{2}-[0-9]{2}:[0-9]{2}$ ]]; then
	echo
	echo "ERROR: incorrect time format. Format is <dd-hh:mm>"
	exit ${ER_WALLTIME}
fi

while : ; do
	echo
	echo -n "New walltime is ${TIME_NEW}. Is this correct? [y/n]: "
	read TIME_CONF
	case ${TIME_CONF} in
		y|Y|yes)
			break
			;;
		n|N|no)
			echo "walltime not set"
			exit ${ER_WALLTIME}
			;;
		*)
			echo
			echo "please select y or n"
			;;
	esac
done

# write walltime to the log file
sed -i 's/^#WALLTIME=.*/#WALLTIME='"${TIME_NEW}"'/' ${LOG}
echo "walltime set"
echo
exit 0
}
######

#add version check here
#it would be cool to be able to update the log file with new information
if [ ! -f ${LOG} ]; then
	log_write
fi

while getopts ":f:t:s:TEhr" opt; do
	case "${opt}" in
		f)	# set com name and check for correct file extension
			if ( echo "${OPTARG}" | grep -q " " ); then
				echo "ERROR: filename cannot contain spaces"
				exit ${ER_SPACES}
			fi
			if [[ "${OPTARG}" = *.com ]] && [ -f ${OPTARG} ]; then
				COM_FULLNAME=${OPTARG}
				COM_NAME=${COM_FULLNAME%.*}
			else
				echo
				echo "ERROR: .com file missing or wrong file extension found"
				echo
				exit ${ER_COM_FILE}
			fi
			;;
		t)	# check time format and set walltime
			if [[ ${OPTARG} =~ ^[0-9]{2}-[0-9]{2}:[0-9]{2}$ ]]; then
				WALLTIME_ALT=${OPTARG}
			else 
				echo "ERROR: incorrect time format. Format is <dd-hh:mm>"
				exit ${ER_TIME_FORMAT}
			fi
			;;
		s) # check to make sure script file is present
			if [ -f ${OPTARG} ]; then
				SCRIPT_ALT=${OPTARG}
			else
				echo "ERROR: script file not found"
				exit ${ER_SCRIPT_ALT}
			fi
			;;
		T) # change default walltime
			walltime_write
			;;
		E) # change email used for notifications
			email_write
			exit 0
			;;
		r)
			#check if putting -f after -r breaks this
			if $( grep -qe 'TD' ${COM_FULLNAME} ) || $( grep -qe 'TDA' ${COM_FULLNAME}) ; then
				RESTART=DISABLED
			else
				RESTART=TRUE
			fi
			;;
		h | ?)
			usage
			;;
	esac
done

#this could probably be moved up. Doesn't make sense to run this script without gaussian access
# ensure user has gaussian access
if ! groups | grep -q soft_gaussian; then
	echo "ERROR: You do not have access to gaussian."
	echo "Ensure you can run module load gaussian successfully before using this script"
	exit ${ER_GAUSSIAN_ACCESS}
fi

# ensure .com file is provided
if [ -z ${COM_FULLNAME} ]; then
	usage
fi

# check for required values in com file
for i in %rwf= %chk= %mem= %nprocshared= ; do
	if ! grep -q "$i" ${COM_FULLNAME}; then
		echo "ERROR: $i missing from .com file"
		exit ${ER_COM_FORMAT}
	fi
done

if [ -n "${SCRIPT_ALT}" ] && [ "${RESTART}" = "TRUE" ]; then
	echo "ERROR: restart can only be used with the default script"
	exit ${ER_RESTART}
fi

# read requested memory from .com file
MEM=$( grep %mem= ${COM_FULLNAME} | head -n 1 )
MEM_VAL=${MEM//[!0-9]/}
MEM_UNIT=${MEM//[!M,G]/}
# set memory value to request and check for errors
if [ "${MEM_UNIT}" = "M" ]; then
	COMP_VALUE=$((COMP_VALUE*1024))
	MEM_VAL=$((MEM_VAL+$COMP_VALUE))
elif [ "${MEM_UNIT}" = "G" ]; then
	MEM_VAL=$((MEM_VAL+$COMP_VALUE))
else
	echo "ERROR: incorrect memory units specified in .com file. Must use MB or GB"
	exit ${ER_MEM_UNIT}
fi

# read requested cpus from .com file
NCPUS=$( grep %nprocshared= ${COM_FULLNAME} | head -n 1 )
NCPUS=${NCPUS//[!0-9]/}

# move this down so it happens just before submission
# set script to be used and write default one if it is not present
SCRIPT=${SCRIPT_ALT:-$SCRIPT_CALC}
if [ -z ${SCRIPT_ALT} ] && [ ! -f ${SCRIPT_CALC} ]; then
	echo
	echo "${SCRIPT_CALC} not found, writing script file"
	script_write
fi

# move up. should happen early
# check if an email has been specified. If it has not been then ask user to set one
EMAIL=$( grep '#EMAIL=' ${LOG} )
EMAIL=${EMAIL#*=}
while [ -z ${EMAIL} ]; do
	echo
	echo "No email has been set"
	email_write
	EMAIL=$( grep '#EMAIL=' ${LOG} )
	EMAIL=${EMAIL#*=}
done

# could make a function for this or just put it all in teh getopts section (probably nicer to make a function)
# set walltime and if RESTART unset set it to FALSE
WALLTIME=$( grep \#WALLTIME= ${LOG} )
WALLTIME=${WALLTIME#*=}
TIME=${WALLTIME_ALT:-$WALLTIME}
RESTART=${RESTART:-FALSE}
if [ "${RESTART}" = "TRUE" ]; then
	TIME_D=${TIME%-*}
	TIME_H=${TIME%:*}
	TIME_H=${TIME_H#*-}
	TIME_M=${TIME#*:}
	TIMEOUT=$( echo "(${TIME_D}*24*60)+(${TIME_H}*60)+${TIME_M}-5" | bc )
else
	TIMEOUT=0
fi

# check with user if values are as desired
echo
echo "The calculation on ${COM_FULLNAME} will be submitted with the following values:"
echo "Email: ${EMAIL}"
echo "Walltime: ${TIME}"
echo "Cores: ${NCPUS}"
echo "Compensated Memory: ${MEM_VAL}${MEM_UNIT}"
echo "Run script: ${SCRIPT}"
echo "Requeue: ${RESTART}"
echo
echo -n "Do you want to submit with these values? [y/n]: "
while : ;do 
	read USE_DEF
	case $USE_DEF in
		y|Y|yes)
			echo
			break
			;;
		n|N|no)
			echo
			echo "To use alternative values specify arguments when executing script or change defaults"
			usage
			;;
		*)
			echo
			echo -en "please select y or n :"
			;;
	esac
done

# Submit the job
echo >> ${LOG}
echo "<submission>" >> ${LOG}
echo "	type: new submission" >> ${LOG}
echo "	script: ${SCRIPT_NAME}" >> ${LOG}
echo "	time: $( date )" >> ${LOG}
echo "	file: $( realpath ${COM_FULLNAME} )" >> ${LOG}
echo "	command: sbatch --mail-user=${EMAIL} --time=${TIME} --mem=${MEM_VAL}${MEM_UNIT} --cpus-per-task=${NCPUS} --output=${COM_NAME}-%j.out --export=COM_NAME=${COM_NAME},EMAIL=${EMAIL},TIME=${TIME},MEM_VAL=${MEM_VAL},MEM_UNIT=${MEM_UNIT},NCPUS=${NCPUS},SCRIPT=${SCRIPT},TIMEOUT=${TIMEOUT},RESTART=${RESTART},LOG=${LOG} ${SCRIPT}" >> ${LOG}
sbatch --mail-user=${EMAIL} --time=${TIME} --mem=${MEM_VAL}${MEM_UNIT} --cpus-per-task=${NCPUS} --output=${COM_NAME}-%j.out --export=COM_NAME=${COM_NAME},EMAIL=${EMAIL},TIME=${TIME},MEM_VAL=${MEM_VAL},MEM_UNIT=${MEM_UNIT},NCPUS=${NCPUS},SCRIPT=${SCRIPT},TIMEOUT=${TIMEOUT},RESTART=${RESTART},LOG=${LOG} ${SCRIPT} | tee -a ${LOG}
if [ ! $? -eq 0 ]; then
	echo "ERROR: submission unsuccessful"
	exit ${ER_SUB_FAIL}
fi
echo "</submission>" >> ${LOG}
exit 0
