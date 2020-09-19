%rwf=<read write file>.rwf
%nosave
%oldchk=<old check point file (if you dont want to overwrite it)>
%chk=<check point file>.chk
%mem=<memory in MB or GB>
%nprocshared=<number of cpus (16 works well)>
# <calculation commands>

<title can be up to 5 lines>

<charge and multiplicity>
<structural data>

<split or custom basis set, etc.>


