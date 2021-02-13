#!/bin/bash

#for nice lighting replace first light with the one below
#light_source {
#    <-127.354228928321, 87.4544433790905, 103.071884398339>, color rgb <1, 1, 1>
#    area_light
#    20, 20, 4, 4
#    adaptive 3
#    jitter
#    circular
#    orient
#}

#usage: ./<script> <filename.pov> <size>
#This only does squares

if ! module list | grep -q "povray" ; then
	module load intel/2018.3
	module load povray
fi

povray +I${1} +O${1%.pov}.png +W${2} +H${2} +FN +Q11 +A +J +AM2 +UA

exit 0
