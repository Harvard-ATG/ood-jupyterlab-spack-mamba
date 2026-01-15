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
    echo "Usage: sbatch installMambaEnvironment.sh <path_to_environment.yml> [spack_env_name]"
    exit 1
fi

ENV_FILE=$1
SPACK_ENV=${2:-mamba}  # Default to 'mamba' if not provided

# Check if file exists
if [ ! -f "$ENV_FILE" ]; then
    echo "Error: Environment file '$ENV_FILE' not found"
    exit 1
fi

echo "Installing environment from: $ENV_FILE"
echo "Using Spack environment: $SPACK_ENV"

# Load spack and mamba
source /shared/spack/share/spack/setup-env.sh

# Check if spack environment exists
if ! spack env list | grep -q "^$SPACK_ENV$"; then
    echo "Error: Spack environment '$SPACK_ENV' not found"
    echo "Available environments:"
    spack env list
    exit 1
fi

# Activate spack environment
spack env activate $SPACK_ENV

# Verify mamba is available
if ! command -v mamba &> /dev/null; then
    echo "Error: mamba not found in spack environment '$SPACK_ENV'"
    echo "Make sure mamba is installed in this environment"
    exit 1
fi

echo "Mamba version: $(mamba --version)"

# Create environment from environment.yml
mamba env create -f "$ENV_FILE"

# Extract environment name from yml file
ENV_NAME=$(grep "^name:" "$ENV_FILE" | awk '{print $2}')

if [ -z "$ENV_NAME" ]; then
    echo "Warning: Could not determine environment name from file"
    ENV_NAME="<unknown>"
fi

echo "Environment installation complete!"
echo "To use: mamba activate $ENV_NAME"