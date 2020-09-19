%rwf=<name of your file>.rwf
%nosave
%chk=<chk point file from structure optimization>.chk
%mem=<memory in MB or GB>
%nprocshared=<number of processors you want to use>
# <wb97xd or lc-hpbe>/<basis set. internal, split, or custom> <dispersion if using lc-hpbe> <solvent model>

===EXTRA===
<basis set information of solvent data should be placed directly below the above text. It will be copied and added to the generated .com files.>

