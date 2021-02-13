#!/bin/bash

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