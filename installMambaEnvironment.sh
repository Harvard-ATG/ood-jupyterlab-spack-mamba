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
    echo "Usage: sbatch installMambaEnvironment.sh <path_to_environment.yml> [spack_env_name] [install_path]"
    echo ""
    echo "Arguments:"
    echo "  path_to_environment.yml : Path to environment.yml file (required)"
    echo "  spack_env_name         : Spack environment to use (default: mamba)"
    echo "  install_path           : Path to install mamba environment (optional)"
    echo ""
    echo "Examples:"
    echo "  # Install by name (from yml file):"
    echo "  sbatch installMambaEnvironment.sh environment.yml"
    echo ""
    echo "  # Install to specific path:"
    echo "  sbatch installMambaEnvironment.sh environment.yml mamba-gpu /shared/courseSharedFolders/165993outer/165993/bst236"
    exit 1
fi

ENV_FILE=$1
SPACK_ENV=${2:-mamba}  # Default to 'mamba' if not provided
INSTALL_PATH=$3        # Optional: path to install environment

# Check if file exists
if [ ! -f "$ENV_FILE" ]; then
    echo "Error: Environment file '$ENV_FILE' not found"
    exit 1
fi

echo "Installing environment from: $ENV_FILE"
echo "Using Spack environment: $SPACK_ENV"

if [ -n "$INSTALL_PATH" ]; then
    echo "Install location: $INSTALL_PATH"
else
    echo "Install location: Default (by environment name)"
fi

# Load spack and mamba
source /shared/spack/share/spack/setup-env.sh

# Verify spack loaded
if ! command -v spack &> /dev/null; then
    echo "Error: Failed to load spack"
    echo "Check that /shared/spack/share/spack/setup-env.sh exists"
    exit 1
fi

echo "Spack loaded successfully"

# Activate spack environment
spack env activate "$SPACK_ENV"

# Verify mamba is available
if ! command -v mamba &> /dev/null; then
    echo "Error: mamba not found in spack environment '$SPACK_ENV'"
    echo "Make sure mamba is installed in this environment"
    exit 1
fi

echo "Mamba version: $(mamba --version)"
echo ""
echo "Starting installation..."

# Create environment from environment.yml
if [ -n "$INSTALL_PATH" ]; then
    # Install to specific path
    echo "Installing to path: $INSTALL_PATH"
    
    if mamba env create -f "$ENV_FILE" --prefix "$INSTALL_PATH"; then
        echo ""
        echo "✅ Environment installation complete!"
        echo "   Location: $INSTALL_PATH"
        echo ""
        echo "To use:"
        echo "   mamba activate $INSTALL_PATH"
    else
        echo "❌ Environment installation failed!"
        exit 1
    fi
else
    # Install by name (default location)
    echo "Installing by name from environment.yml"

    if mamba env create -f "$ENV_FILE"; then
        # Extract environment name from yml file
        ENV_NAME=$(grep "^name:" "$ENV_FILE" | awk '{print $2}')
    
        if [ -z "$ENV_NAME" ]; then
            echo "Warning: Could not determine environment name from file"
            ENV_NAME="<unknown>"
        fi
        
        echo ""
        echo "✅ Environment installation complete!"
        echo "   Name: $ENV_NAME"
        echo ""
        echo "To use:"
        echo "   mamba activate $ENV_NAME"
    else
        echo "❌ Environment installation failed!"
        exit 1
    fi
fi