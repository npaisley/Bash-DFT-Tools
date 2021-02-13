#!/bin/bash

#for soft lighting add the below text to the first light (text from area_light to orient)
#light_source {
#    < existing stuff >
#    area_light
#    20, 20, 4, 4
#    adaptive 3
#    jitter
#    circular
#    orient
#}
#altenatively the line shadowless can be added to lights to remove shadows. This makes the figure look boring but can make them easier to interpret

#usage: ./<script> <filename.pov> <size>

#This only does squares. you can make it do rectangles if you want to
#I don't want it to so it doesn't
#IMPORTANT! When making the *.pov file with avogadro you must tell it to render a square (ex. 1024 x 1024)
#If you choose a rectangle in avogadro and then render using this script your figure will be messed up look stretched
#This can be fixed by changing this script to have different width and height and then using dimsensions with the same aspect ratio as what you chose in avogadro
#but as I said above it don't want this script to do this. It's just not worth it.so if you want the script to do this you're on your own. I wish you luck.
#Moreover, you can just crop the square. You can even incude this in a loop with this script to render and crop all your images in one shot
#to do this use imagemagick
#you will need to load the imagemagick module (ex. ]$ module load imagemagick)
#then use ]$ convert <input>.png -trim <output>.png
#Boom! you now have a cropped image. Enjoy.
# Nathan Paisley Feb 2021

#load required modules if they aren't loaded
if ! module list | grep -q "povray" ; then
	module load intel/2018.3
	module load povray
fi

#render the thing.
povray +I${1} +O${1%.pov}.png +W${2} +H${2} +FN +Q11 +A +J +AM2 +UA

exit 0
