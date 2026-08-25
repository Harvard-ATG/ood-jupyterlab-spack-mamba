#!/bin/bash
#SBATCH --job-name=mamba-install
#SBATCH --output=mamba-install-%j.out
#SBATCH --error=mamba-install-%j.err
#SBATCH --time=01:00:00
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4
#SBATCH --mem=8G

#Created with help of claude 4.5 AI Model

# Default values
SPACK_ENV="mamba"
INSTALL_PATH=""
ENV_NAME_OVERRIDE=""
FORCE=""

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
    echo "  -y             Overwrite an existing environment at the target prefix without prompting"
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
    echo ""
    echo "  # Re-install over an existing environment (e.g. to pick up a new activate.d hook):"
    echo "  sbatch installMambaEnvironment.sh -f environment.yml -y"
    exit 1
}

# Parse arguments
while getopts "f:s:p:n:yh" opt; do
    case $opt in
        f) ENV_FILE="$OPTARG" ;;
        s) SPACK_ENV="$OPTARG" ;;
        p) INSTALL_PATH="$OPTARG" ;;
        n) ENV_NAME_OVERRIDE="$OPTARG" ;;
        y) FORCE="--yes" ;;
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
    mamba env create -f "$ENV_FILE" --prefix "$INSTALL_PATH" $FORCE
    INSTALL_STATUS=$?
    ACTIVATION="mamba activate $INSTALL_PATH"
    ENV_PREFIX="$INSTALL_PATH"

elif [ -n "$ENV_NAME_OVERRIDE" ]; then
    echo "Installing with custom name: $ENV_NAME_OVERRIDE"
    mamba env create -f "$ENV_FILE" -n "$ENV_NAME_OVERRIDE" $FORCE
    INSTALL_STATUS=$?
    ACTIVATION="mamba activate $ENV_NAME_OVERRIDE"
    ENV_PREFIX=$(mamba run -n "$ENV_NAME_OVERRIDE" bash -c 'echo $CONDA_PREFIX')

else
    echo "Installing by name from environment.yml"
    mamba env create -f "$ENV_FILE" $FORCE
    INSTALL_STATUS=$?
    ENV_NAME=$(grep "^name:" "$ENV_FILE" | awk '{print $2}')
    ACTIVATION="mamba activate ${ENV_NAME:-<unknown>}"
    ENV_PREFIX=$(mamba run -n "$ENV_NAME" bash -c 'echo $CONDA_PREFIX')
fi

if [ $INSTALL_STATUS -eq 0 ]; then
    # Install any activation hooks that live alongside the environment.yml
    # (e.g. mamba-environment/<course>/activate.d/*.sh). These run automatically
    # every time this environment is activated - see:
    # https://docs.conda.io/projects/conda/en/latest/user-guide/tasks/manage-environments.html#saving-environment-variables
    ACTIVATE_D_SRC="$(dirname "$ENV_FILE")/activate.d"
    if [ -d "$ACTIVATE_D_SRC" ]; then
        echo "Installing activation hooks from $ACTIVATE_D_SRC into $ENV_PREFIX/etc/conda/activate.d/"
        mkdir -p "$ENV_PREFIX/etc/conda/activate.d"
        cp "$ACTIVATE_D_SRC"/*.sh "$ENV_PREFIX/etc/conda/activate.d/"
        chmod +x "$ENV_PREFIX/etc/conda/activate.d/"*.sh
    fi

    echo ""
    echo "✅ Environment installation complete!"
    echo ""
else
    echo "❌ Environment installation failed!"
    exit 1
fi