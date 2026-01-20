#!/bin/bash
#SBATCH --job-name=mamba-install
#SBATCH --output=mamba-install-%j.out
#SBATCH --error=mamba-install-%j.err
#SBATCH --time=01:00:00
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4
#SBATCH --mem=8G

# Default values
SPACK_ENV="mamba"
INSTALL_PATH=""
ENV_NAME_OVERRIDE=""

# Usage function
usage() {
    echo "Usage: sbatch installMambaEnvironment.sh -f <environment.yml> [options]"
    echo ""
    echo "Required:"
    echo "  -f FILE        Path to environment.yml file"
    echo ""
    echo "Options:"
    echo "  -s ENV         Spack environment name (default: mamba)"
    echo "  -p PATH        Install to specific path"
    echo "  -n NAME        Override environment name"
    echo "  -h             Show this help"
    echo ""
    echo "Examples:"
    echo "  # Install by name from yml:"
    echo "  sbatch installMambaEnvironment.sh -f environment.yml"
    echo ""
    echo "  # Install with custom name:"
    echo "  sbatch installMambaEnvironment.sh -f environment.yml -n bst236-cpu"
    echo ""
    echo "  # Install to specific path:"
    echo "  sbatch installMambaEnvironment.sh -f environment.yml -p /shared/.../bst236-gpu"
    echo ""
    echo "  # Use different spack env with custom name:"
    echo "  sbatch installMambaEnvironment.sh -f environment.yml -s mamba-gpu -n bst236-gpu"
    exit 1
}

# Parse arguments
while getopts "f:s:p:n:h" opt; do
    case $opt in
        f) ENV_FILE="$OPTARG" ;;
        s) SPACK_ENV="$OPTARG" ;;
        p) INSTALL_PATH="$OPTARG" ;;
        n) ENV_NAME_OVERRIDE="$OPTARG" ;;
        h) usage ;;
        *) usage ;;
    esac
done

# Check required arguments
if [ -z "$ENV_FILE" ]; then
    echo "Error: environment.yml file required"
    usage
fi

if [ ! -f "$ENV_FILE" ]; then
    echo "Error: Environment file '$ENV_FILE' not found"
    exit 1
fi

echo "Installing environment from: $ENV_FILE"
echo "Using Spack environment: $SPACK_ENV"

# Load spack and mamba
source /shared/spack/share/spack/setup-env.sh
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

# Determine installation method
if [ -n "$INSTALL_PATH" ]; then
    echo "Installing to path: $INSTALL_PATH"
    mamba env create -f "$ENV_FILE" --prefix "$INSTALL_PATH"
    ACTIVATION="mamba activate $INSTALL_PATH"

elif [ -n "$ENV_NAME_OVERRIDE" ]; then
    echo "Installing with custom name: $ENV_NAME_OVERRIDE"
    mamba env create -f "$ENV_FILE" -n "$ENV_NAME_OVERRIDE"
    ACTIVATION="mamba activate $ENV_NAME_OVERRIDE"

else
    echo "Installing by name from environment.yml"
    mamba env create -f "$ENV_FILE"
    ENV_NAME=$(grep "^name:" "$ENV_FILE" | awk '{print $2}')
    ACTIVATION="mamba activate ${ENV_NAME:-<unknown>}"
fi

if [ $? -eq 0 ]; then
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