#!/bin/bash
#SBATCH --job-name=AUTOART_ARRAY
#SBATCH --time=12-00:00:00
#SBATCH --mem=64G
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --array=1-60

cd ~/MATLAB/autoart
module load matlab/2020a
matlab -nodesktop -nosplash < "trial_autoart.m"
