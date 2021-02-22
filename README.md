# Bash DFT Tools
Collection of bash shell scripts for use submitting jobs, making input files, and extracting information
Designed to use on compute canada servers that are running SLURM.  

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
For use with SLURM  
Reads your gaussian .com file and sets `sbatch` settings for you to avoid mistakes or the headache of doing it manually for many files. 
Additionally, it writes a run script for gaussian 16 calculations. This allows for opt and freq calculations to be restarted by the script without your input.    
Run using `./sg16submit-Mkx.x.x.sh -f <file.com> [-t <dd-hh:mm>] [-s <script>] [-r] [-h] [-T] [-E]`

`-f` designates the .com file to be used and is the only required argument  
`-t` requests a temporary, non-default, walltime be used  
`-s` requests for a named alternative script to be used  
`-r` requests that the calculation be set to requeue itself upon timeout. This only works with the default script  
`-h` displays the help information  
`-T` changes the default time  
`-E` changes the email notifications are sent to  

## multiComWriter.sh  

## NTOcomwriter.sh  

## RSHOpt.sh  

## valueExtractor.sh    
Extracts HOMO, LUMO, dipole, total energy, S1, and T1 information from gaussian log files and outputs a comma separated string. The ouput can be directed to a file or to the command line. If ouput is directed to a file the header will only be printed once.  
Run using `./valueExtractor.sh <log file>.log [<file name>.csv]`. The second argument is the ouput file. This is not required. 
To analyze a batch of files use in a for loop (ex. ` for F in *.log ; do /valueExtractor.sh ${F} <file name>.csv ; done`)  

## gparse.sh  

## qstat.sh  

## renderPovrayGraham.sh

## Memory Tips  
When making your gaussian input file you should choose an amout of memory that fits the server architecture available to you (remember that the sg16submit script adds 2 G of memory to your requested amount). For [Graham](https://docs.computecanada.ca/wiki/Graham) this is as follows:  
903 nodes with 32 cores and 3.9 G per core  
24 nodes with 32 cores and 15.7 G per core  
56 nodes with 32 cores and 7.8 G per core  
3 nodes with 64 cores and 47.2 G per core  
72 nodes with 44 cores and 4.4 G per core  
