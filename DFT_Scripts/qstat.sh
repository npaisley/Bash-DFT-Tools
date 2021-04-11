#!/bin/bash
#cute little script to give you quick and simple information about your slurm queue
#now formatted so that it looks pretty!
#most useful to alias in your .bashrc file
#for example: in your home directory open your .bashrc file with a text editor of your choosing add the line 
# alias qs="~/Bash-DFT-Tools/DFT_Scripts/qstat.sh"
#to the alias section of your .bashrc file and save
#make sure qstat.sh can be executed or this won't work
#you can then use the command qs anytime to run this script

summary_short () {
# set dynamic line length
LINE="$( echo "Scratch files to be deleted: $( wc -l < /home/scratch_to_delete/${USER} )" | tr "[:print:]" "-" )"
#total queue
TOTAL=$( echo "${QUEUE}" | wc -l )
# use echo "words" | tr "[:print:]" "-" for a dynamic line
echo "${LINE}"
echo "$( tput bold )Total queue:$(tput sgr0)" $(( TOTAL - 1 ))
#running
echo " $( tput bold )Running:$(tput sgr0)   " $( echo "${QUEUE}" | grep -c '(None)' )
#in queue
echo " $( tput bold )Priority:$(tput sgr0)  " $( echo "${QUEUE}" | grep -c '(Priority)' )
#priority
echo " $( tput bold )Resources:$(tput sgr0) " $( echo "${QUEUE}" | grep -c '(Resources)' )
#resources
echo "${LINE}"
echo "$( tput bold )Scratch files to be deleted:$(tput sgr0)" $( wc -l < /home/scratch_to_delete/${USER} )
echo "${LINE}"
}

summary_long () {
# print the jobids of the running jobs and their corresponding files
for JOBID in $( sq -h | grep -oE '^[[:space:]]{0,}[0-9]{1,}' | xargs ) ; do 
    # if the jobid is found in the scratch file system then print the file that is running
    if $( ls -R ~/scratch/ | grep -q "${JOBID}" ) ; then
        echo "${JOBID} running: $( ls -R ~/scratch/ | grep "${JOBID}" )"
    # if the jobid is not found in the scratch folder then search the sg16 log for it
    elif $( grep -a -q "${JOBID}" ~/sg16log/sg16submit.log ) ; then
        echo "${JOBID} queued: $( grep -a -B 2 "${I}" ~/sg16log/sg16submit.log | head -n 1 | grep -oE '[^/]{1,}$')"
    # if the jobid cannot be found anywhere inform the user
    else
        echo "${JOBID} not found"
    fi
done
}

QUEUE=$(sq)
while getopts ":l" OPTION ; do
  case ${OPTION} in
    l ) # display long summary
        summary_short
        summary_long
        exit 0
        ;;
    h ) # display help message
        echo "./sqtat.sh [-l] [-h]"
        echo "-l : give longer printout
        echo "-h : prints this message"
        echo 'if no argument is provided a short summary is printed'
        exit 0
        ;;
    \? ) # display short summary
        summary_short
        exit 0
        ;;
  esac
done

exit 0

