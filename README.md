# HudsonGroup
Collection of bash shell scripts for use submitting jobs, making input files, and extracting information
Designed to use on compute canada serveers that are running SLURM
submitting jobs with SLURM: sg16submit-Mkx.x.x.x.sh

# sg16submit-Mkx.x.x.x.sh
reads your com file and sets `sbatch` settings for your to avoid mistakes or teh headache of doing it manually for many files
Additionally, it wries a run script for gaussian 16 calculations. This allows for opt and freq calculations to be restarted by the script without your input
