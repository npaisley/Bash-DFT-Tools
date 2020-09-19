# Bash DFT Tools
Collection of bash shell scripts for use submitting jobs, making input files, and extracting information
Designed to use on compute canada serveers that are running SLURM

Within the DFT_Sripts folder the following files are found:  
[sg16submit-Mkx.x.x.x.sh](#sg16submitsh)  
[multiComWriter.sh](#multicomwritersh)  
[NTOcomwriter.sh](#ntocomwritersh)  
[RSHOpt-Mkx.x.x.sh](#rshoptsh)  
[valueExtractor-optfreq.sh](#valueExtractor-optfreqsh)  
[valueExtractor-TDDFT.sh](#valueExtractor-tddftsh)  
[gparse.sh](#gparsesh)  

## sg16submit.sh
For use with SLURM  
Reads your gaussian .com file and sets `sbatch` settings for you to avoid mistakes or the headache of doing it manually for many files. 
Additionally, it wries a run script for gaussian 16 calculations. This allows for opt and freq calculations to be restarted by the script without your input

## multiComWriter.sh  
## NTOcomwriter.sh  
## RSHOpt.sh  
## valueExtractor-optfreq.sh  
## valueExtractor-TDDFT.sh  
## gparse.sh