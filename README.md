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
Reads your gaussian input file (.com file) and sets `sbatch` arguments for you. This helps avoid mistakes and saves time when submitting multiple calculations. This is the only file required when submitting gaussian calculations as all other required files will be written by this script. The `-r` argument requests that calculations automatically be requeued upon reaching their wall-time.  
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
The Gaussian 16 run script will be written if it is not found in the same folder as this submission script.  

### First Run
When run for the first time a dialg will appear that asks you to input your email. This is required for notifications (via email) regarding the status of your calculations. Additonally, a file named sg16log will be made in your home directory (/home/\<username\>). Inside is a log file containing the values for the wall-time, your email, and information regarding every calculation submitted by this script or the defualt run script.  

### Restart
The wall-time is passed on to the run script so that long running calulations can be automatically resubmitted and restarted. This currently only work with opt and freq calculations. It is currently disabled (even with the `-r` argument) for TD-DFT calulations as an error occurs with the employed method of restarting calulations and the calulations has to be started fresh. An email stating that the calculation ended with exit code 77 indicates that the calculation was resubmitted to SLURM successfully. An exit code of 66 indicates unsuccessful resubmission. All other exit codes are from the calculation itself.  

## multiComWriter.sh  

## NTOcomwriter.sh  

## RSHOpt.sh  

## valueExtractor.sh    
Extracts HOMO, LUMO, dipole, total energy, S1, and T1 information from gaussian log files and outputs a comma separated string. The ouput can be directed to a file or to the command line. If ouput is directed to a file the header will only be printed once.  

Run using `./valueExtractor.sh <log file>.log [<file name>.csv]`. The second argument is the ouput file. This is not required. 
To analyze a batch of files in a for loop use in the following fashion: ` for F in *.log ; do /valueExtractor.sh ${F} <file name>.csv ; done`  

## gparse.sh  

## qstat.sh  

## renderPovrayGraham.sh

## Tips  
### Memory  
When making your gaussian input file you should choose an amout of memory that fits the server architecture available to you (remember that the sg16submit script adds 2 G of memory to your requested amount). For [Graham](https://docs.computecanada.ca/wiki/Graham) this is as follows:  
903 nodes with 32 cores and 3.9 G per core  
24 nodes with 32 cores and 15.7 G per core  
56 nodes with 32 cores and 7.8 G per core  
3 nodes with 64 cores and 47.2 G per core  
72 nodes with 44 cores and 4.4 G per core  
