#!/bin/bash
#SBATCH --job-name=mamba-install
#SBATCH --output=mamba-install-%j.out
#SBATCH --error=mamba-install-%j.err
#SBATCH --time=01:00:00
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4
#SBATCH --mem=8G

# Check if environment file was provided
if [ -z "$1" ]; then
    echo "Error: No environment file provided"
    echo "Usage: sbatch installMambaEnvironment.sh <path_to_environment.yml>"
    exit 1
fi

ENV_FILE=$1

# Check if file exists
if [ ! -f "$ENV_FILE" ]; then
    echo "Error: Environment file '$ENV_FILE' not found"
    exit 1
fi

echo "Installing environment from: $ENV_FILE"

# Load spack and mamba
source /shared/spack/share/spack/setup-env.sh
spack env activate mamba

# Create environment from environment.yml with parallel jobs
mamba env create -f "$ENV_FILE" -j $SLURM_CPUS_PER_TASK

echo "Environment installation complete!"
echo "To use: mamba activate <env_name>"