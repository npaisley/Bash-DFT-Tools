# Bash DFT Tools
This is a collection of bash shell scripts for submitting jobs, making input files, and extracting data from completed calculations. They were designed for use on compute canada servers that are running SLURM. I have not tested them on other systems so they may or may not work in such senarios. In addition to these scripts I have also included a troubleshooting document with problems that I have encountered and their respective solutions. The trobleshooting document and this readme are formatted using markdown (.md file extension) and are therefore most easily viewed using a markdown editor (such as [Typora](https://typora.io/)) or more simply by viewing them on the [Github](https://github.com/npaisley/Bash-DFT-Tools) website.  

Within the DFT_Sripts folder the following files are found:  
[sg16submit-Mkx.x.x.x.sh](#sg16submitsh)  
[multiComWriter.sh](#multicomwritersh)  
[NTOcomwriter.sh](#ntocomwritersh)  
[RSHOpt-Mkx.x.x.sh](#rshoptsh)  
[valueExtractor.sh](#valueextractorsh)    
[gparse.sh](#gparsesh)  
[qstat.sh](#qstatsh)  
[renderPovrayGraham.sh](#renderpovraygrahamsh)  

## sg16submit.sh
Reads your gaussian input file (.com file) and sets `sbatch` arguments for you. This helps avoid mistakes and saves time when submitting multiple calculations. This is the only file required when submitting gaussian calculations as all other required files will be written by this script.    
**NOTE:** This run script is intended to be used in the same folder as your gaussian input file.  

Run using:  
 `./sg16submit-Mkx.x.x.sh -f <file.com> [-t <dd-hh:mm>] [-s <script>] [-r] [-h] [-T] [-E]`

`-f` designates the .com file to be used and is the only required argument  
`-t` requests a temporary, non-default, walltime be used  
`-s` requests that a non-default run script be used  
`-r` requests that the calculation requeue itself upon reaching its wall-time. This only works with the default script  
`-h` displays the help information  
`-T` changes the default wall-time  
`-E` changes the email notifications are sent to  

### General Infomation
- The Gaussian 16 run script will be written if it is not found in the same folder as this submission script.  
- 2 GB more memory than is specified in the input file is requested from SLURM. This is done because Gaussian typically uses 1 - 2 GB more memory than it is told it has in the input file. If more memory than "needed" is not requested than Gaussian will run out of memory and the calculation will error out.  

### First Run
When run for the first time a dialg will appear that asks you to input your email. This is required for notifications (via email) regarding the status of your calculations. Additonally, a file named sg16log will be made in your home directory (/home/\<username\>). Inside is a log file containing the values for the wall-time, your email, and information regarding every calculation submitted by this script or the defualt run script.  

### Restart
The wall-time is passed on to the run script so that long running calulations can be automatically resubmitted and restarted. This currently only work with opt and freq calculations. It is currently disabled (even with the `-r` argument) for TD-DFT calulations as an error occurs with the employed method of restarting calulations and the calulations has to be started fresh. An email stating that the calculation ended with exit code 77 indicates that the calculation was resubmitted to SLURM successfully. An exit code of 66 indicates unsuccessful resubmission. All other exit codes are from the calculation itself.  

## multiComWriter.sh  
This script is being rewritten. Once done it will enable the writing on multiple gaussian input files with ease.  

## NTOcomwriter.sh  
Takes a completed TD or TDA calculation and writes .com files for the generation of S<sub>1</sub> and T<sub>1</sub> of natural transition orbitals (NTOs) with gaussian. Requires the .log and .chk files to be present. Run using:  
`./NTOcomwriter.sh <file.com>`  

## RSHOpt.sh  
The boundary values in the script can be changed to speed up calculations if you are confident that the optimum w value is still within the bounded range. If the script determines that the optimum value (or a value very close to it) is the optimum value then you have set the boundary too tight and you should re-run the optimization with a wider boundary.  
  
The easiest way to run this is using `./sg16submit-Mkx.x.x.sh -f <file.com> [-t <dd-hh:mm>] -s RSHOpt-Mkx.x.x.sh`. This requests the sg16submit script to use the RSHOpt run script instead of the default one. Make sure that the input file (file.com) is made following the example RSHOpt input format. If it does not then calculation will fail. Also, it is essential that a check point file with the **exact** same name as the input .com file is present of the calculation will fail.  
  
**NOTE:** I highly suggest you run these in there own file as a large amount of files are written.
**NOTE:** The sg16submit restart option does not currently work with RSHOpt calculations, however, if the optimization times out and is resubmitted it will restart from where it left off.

## valueExtractor.sh    
Extracts HOMO, LUMO, dipole, total energy, S1, and T1 information from gaussian log files and outputs a comma separated string. The ouput can be directed to a file or to the command line. If ouput is directed to a file the header will only be printed once.  

Run using `./valueExtractor.sh <log file>.log [<file name>.csv]`. The second argument is the ouput file. This is not required. 
To analyze a batch of files in a for loop use in the following fashion: ` for F in *.log ; do /valueExtractor.sh ${F} <file name>.csv ; done`  

## gparse.sh  
Was made to extract two-electron integral data from gaussian log files. I will be surprised if anyone needs to use this.  

## qstat.sh  
Alternative to using `squeue` on servers running Slurm. Running the script without any arguments gives a brief summary of the total number of jobs you have submitted and a break down of how many are running or queued. Additionally, the number of files that are set to be deleted from your scratch folder is also printed. For example:  
```
]$ ./qstat.sh
----------------------------------------------
Total queue: 4
 Running:    3
 Priority:   1
 Resources:  0
----------------------------------------------
Scratch files to be deleted: 1
----------------------------------------------
```
If the `-l` argument is used information about which files are being calculated is printed. Any other argument will result in help text being printed. For example:  
```
]$ ./qstat.sh -l
----------------------------------------------
Total queue: 4
 Running:    3
 Priority:   1
 Resources:  0
----------------------------------------------
Scratch files to be deleted: 1
----------------------------------------------
46809868 running: HMAT3HAZ-RSHopt-46809868.out
46809870 running: TBA3HAZ-RSHopt-46809870.out
46809871 running: TBA3TAZ-RSHopt-46809871.out
46861313 queued: HMAT3TAZ-RSHopt.com
----------------------------------------------
```
It is useful to alias this script in your .bashrc file. This makes it easy and convenient to use. To do this open your .bashrc file (located in your home folder) with a text editor of your choosing and add the line `alias qs="~/Bash-DFT-Tools/DFT_Scripts/qstat.sh"` to the bottom of your .bashrc file and save. Change the file path to match where qstat.sh is and change `qs` to whatever command you would like to use to call the qstat script. You can then use the command `qs` or `qs -l` anytime to run this script. In the example above I have used `qs` and the script is saved in my home directory within the cloned github repository. For example:  
```
<words and stuff>
# User specific aliases and functions
alias qs="~/Bash-DFT-Tools/DFT_Scripts/qstat.sh"
```
Aliasing the file in the cloned respository allows you to take advantage of any updates to the script by simpling pulling (using `git pull`) the repository. 

## renderPovrayGraham.sh
If you choose to render POVray files on a computecanada server this makes things simpler. Until this readme is updated again, look in the script itself for instrucions on how to use it. 

## Tips  
### Memory  
When making your gaussian input file you should choose an amout of memory that fits the server architecture available to you. For [Graham](https://docs.computecanada.ca/wiki/Graham) this is as follows:  

| Number of Nodes | Cores per node | Memory per node (G) | Approximate G/core |
|---|---|---|---|
| 903 | 32 | 125   | 3.9  |
| 24  | 32 | 502   | 15.7 |
| 56  | 32 | 250   | 7.8  |
| 3   | 64 | 3022  | 47.2 |
| 72  | 44 | 192   | 4.4  |
 
**IMPORTANT:** The sg16submit.sh script requests 2 G more memory from SLURM than is specified in your input file. Make sure to adjust the memory you request so that the **final amount** of memory requested matches the node memory.  

### Formchk Runs Out of Memory  
use `GAUSS_MEMDEF=<memory amount in words>` For example, if formchk says it needs 500MW then use `GAUSS_MEMDEF=5000000000`.  
**IMPORTANT:** This needs to be used directly before calling formchk.  
Example:  
```
GAUSS_MEMDEF=5000000000 formchk fancyMolecule.chk
```
In a loop:  
```
for F in *.chk ; do GAUSS_MEMDEF=5000000000 formchk ${F} ; done
```


