#!/bin/bash
#cute little script to give you quick and simple information about your slurm queue
#most useful to alias in your .bashrc file
#for example: in your home directory open your .bashrc file with a text editor of your choosing
#add the line 
# alias qs="~/Bash-DFT-Tools/DFT_Scripts/qstat.sh"
#to the alias section of your .bashrc file and save
#make sure qstat.sh can be executed or this won't work 

QUEUE=$(sq)
#total
TOTAL=$( echo "${QUEUE}" | wc -l )
echo "Total queue:" $(( TOTAL - 1 ))
#running
echo "Running:" $( echo "${QUEUE}" | grep -c '(None)' )
#in queue
echo "Queued"
echo "Priority:" $( echo "${QUEUE}" | grep -c '(Priority)' )
#priority
echo "Resources:" $( echo "${QUEUE}" | grep -c '(Resources)' )
#resources
echo
echo "Scratch files to be deleted: " $( wc -l < /home/scratch_to_delete/${USER} )

exit 0
