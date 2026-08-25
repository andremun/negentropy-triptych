#!/bin/bash
#SBATCH --job-name=AUTOART_ARRAY
#SBATCH --time=48:00:00
#SBATCH --mem=16G
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --array=1-1000

# Copyright (c) 2026 Mario Andres Munoz Acosta
# The University of Melbourne
#
# Date: August 2026
#
# This software is licensed under the PolyForm Noncommercial License 1.0.0.
# You may use, copy, modify, and distribute this software for any
# non-commercial purpose. Commercial use is prohibited.
# Full license text: https://polyformproject.org/licenses/noncommercial/1.0.0
#
# Required Notice: Copyright (c) 2026 Mario Andres Munoz Acosta
#                  The University of Melbourne

cd ~/MATLAB/autoart
module load matlab/2020a
matlab -nodesktop -nosplash < "trial_randart.m"
