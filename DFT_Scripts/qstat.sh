#!/bin/bash
#cute little script to give you quick and simple information about your slurm queue
#now formatted so that it looks pretty!
#most useful to alias in your .bashrc file
#for example: in your home directory open your .bashrc file with a text editor of your choosing add the line 
# alias qs="~/Bash-DFT-Tools/DFT_Scripts/qstat.sh"
#to the alias section of your .bashrc file and save
#make sure qstat.sh can be executed or this won't work
#you can then use the command qs anytime to run this script

QUEUE=$(sq)
#total
TOTAL=$( echo "${QUEUE}" | wc -l )
echo "------------------------------"
echo "$( tput bold )Total queue:$(tput sgr0)" $(( TOTAL - 1 ))
#running
echo " $( tput bold )Running:$(tput sgr0)   " $( echo "${QUEUE}" | grep -c '(None)' )
#in queue
echo " $( tput bold )Priority:$(tput sgr0)  " $( echo "${QUEUE}" | grep -c '(Priority)' )
#priority
echo " $( tput bold )Resources:$(tput sgr0) " $( echo "${QUEUE}" | grep -c '(Resources)' )
#resources
echo "------------------------------"
echo "$( tput bold )Scratch files to be deleted:$(tput sgr0)" $( wc -l < /home/scratch_to_delete/${USER} )
echo "------------------------------"

# use below to display files that correspond to the running calculations
# for I in $( sq -h | grep -oE '^[[:space:]]{0,}[0-9]{1,}' | xargs ) ; do ls -R ~/scratch/ | grep "${I}" ; done
exit 0
