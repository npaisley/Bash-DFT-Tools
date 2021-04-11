#!/bin/bash
#Nathan R. Paisley, April 2021
#cute little (well its a bit fat now) script to give you quick and simple information about your slurm queue
#without any arguments a short summary will display. If the -l argument is used a longer summary will display
#-h or any other -<alpha> will display a help message
#now formatted so that it looks pretty! Wow!
#And with dynamic line lengths! What!?
### NOTE ###
#most useful to alias in your .bashrc file
#for example: in your home directory open your .bashrc file with a text editor of your choosing add the line 
# alias qs="~/Bash-DFT-Tools/DFT_Scripts/qstat.sh"
#to the alias section of your .bashrc file and save
#you can then use the command qs or qs -l anytime to run this script

summary_short () {
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
        echo "${JOBID} running: $( tput bold )$( ls -R ~/scratch/ | grep "${JOBID}" )$( tput sgr0 )"
    # if the jobid is not found in the scratch folder then search the sg16 log for it
    elif $( grep -a -q "${JOBID}" ~/sg16log/sg16submit.log ) ; then
        echo "${JOBID} queued: $( tput bold )$( grep -a -B 2 "${JOBID}" ~/sg16log/sg16submit.log | head -n 1 | grep -oE '[^/]{1,}$')$( tput sgr0 )"
    # if the jobid cannot be found anywhere inform the user
    else
        echo "${JOBID} not found"
    fi
done
echo "${LINE}"
}

usage () {
LINE="$( echo "-l : Prints additional information on the queued and running calculations" | tr [:print:] - )"
echo "${LINE}"
echo "$( tput bold )usage: ./sqtat.sh [-l] [-h]$( tput sgr0 )"
echo '-l : Prints additional information on the queued and running calculations'
echo '-h : prints this message'
echo 'if no argument is provided a short summary is printed'
echo "${LINE}"
}

QUEUE=$(sq)
#parse any given arguments
while getopts ":l" OPTION ; do
  case ${OPTION} in
    l ) # display long summary
        # set dynamic line length via an overcomplicated method
        LINE=0
        for JOBID in $( sq -h | grep -oE '^[[:space:]]{0,}[0-9]{1,}' | xargs ) ; do 
            if $( ls -R ~/scratch/ | grep -q "${JOBID}" ) ; then
                LINE_ST="${JOBID} running: $( ls -R ~/scratch/ | grep "${JOBID}" )"
            elif $( grep -a -q "${JOBID}" ~/sg16log/sg16submit.log ) ; then
                LINE_ST="${JOBID} queued: $( grep -a -B 2 "${JOBID}" ~/sg16log/sg16submit.log | head -n 1 | grep -oE '[^/]{1,}$')"
            fi
            if [[ "$( echo "${LINE_ST}" | wc -L )" -gt "${LINE}" ]] ; then
                LINE="$( echo "${LINE_ST}" | wc -L )"
            fi
        done
        LINE="$( printf '%0.s-' $(seq 1 ${LINE}) )"
        summary_short
        summary_long
        exit 0
        ;;
    ? ) # display help message
        usage
        exit 0
        ;;
  esac
done

# if no argument is passed then print a short summary
# set dynamic line length
LINE="$( echo "Scratch files to be deleted: $( wc -l < /home/scratch_to_delete/${USER} )" | tr "[:print:]" "-" )"
summary_short

exit 0
