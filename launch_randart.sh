#!/bin/bash
#SBATCH --job-name=AUTOART_ARRAY
#SBATCH --time=48:00:00
#SBATCH --mem=16G
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --array=1-1000

cd ~/MATLAB/autoart
module load matlab/2020a
matlab -nodesktop -nosplash < "trial_randart.m"
