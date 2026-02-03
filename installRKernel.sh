#!/bin/bash
#SBATCH --job-name=r-kernel-build
#SBATCH --output=r-kernel-%j.out
#SBATCH --error=r-kernel-%j.err
#SBATCH --time=01:30:00
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4
#SBATCH --mem=16G

#Created with help of Gemini 3.0 Pro AI Model

# -------------------------------------------------------------------------
# SCRIPT: R Kernel Builder (Generic)
# -------------------------------------------------------------------------
# Purpose: Builds a Spack R environment and registers it as a Jupyter Kernel.
#          Designed to be course-agnostic.
# -------------------------------------------------------------------------

# --- DEFAULT CONFIGURATION (Generic) ---
# Default to a common folder name
SPACK_YAML_DIR="./spack-environment/r-gpu-common"

# Default to a generic environment name
ENV_NAME="r-gpu-common"

# Default to a generic system kernel name
KERNEL_NAME="r_gpu_common"

# Default to a clear, generic label for the user
DISPLAY_NAME="R (GPU Enabled)"

# Usage function
usage() {
    echo "Usage: sbatch installRKernel.sh [options]"
    echo ""
    echo "Options:"
    echo "  -d DIR         Directory containing spack.yaml (default: $SPACK_YAML_DIR)"
    echo "  -n NAME        Spack environment name (default: $ENV_NAME)"
    echo "  -k KERNEL      Internal kernel name (default: $KERNEL_NAME)"
    echo "  -l LABEL       Jupyter display label (default: '$DISPLAY_NAME')"
    echo "  -h             Show this help"
    echo ""
    echo "Examples:"
    echo "  # 1. Build the shared generic kernel:"
    echo "  sbatch installRKernel.sh"
    echo ""
    echo "  # 2. Build a specific version for a course:"
    echo "  sbatch installRKernel.sh -n r-apcomp297r -l 'R (APCOMP 297R)'"
    exit 1
}

# Parse arguments
while getopts "d:n:k:l:h" opt; do
    case $opt in
        d) SPACK_YAML_DIR="$OPTARG" ;;
        n) ENV_NAME="$OPTARG" ;;
        k) KERNEL_NAME="$OPTARG" ;;
        l) DISPLAY_NAME="$OPTARG" ;;
        h) usage ;;
        *) usage ;;
    esac
done

# Check required files
if [ ! -f "$SPACK_YAML_DIR/spack.yaml" ]; then
    echo "Error: spack.yaml not found in '$SPACK_YAML_DIR'"
    exit 1
fi

echo "=========================================="
echo "Installing R Kernel Environment"
echo "Source Dir:    $SPACK_YAML_DIR"
echo "Target Env:    $ENV_NAME"
echo "Kernel Label:  $DISPLAY_NAME"
echo "=========================================="

# 1. Load Spack
source /shared/spack/share/spack/setup-env.sh

# 2. Create or Activate Environment
if spack env list | grep -q "^${ENV_NAME}$"; then
    echo "Info: Environment '$ENV_NAME' exists. Activating..."
else
    echo "Info: Creating '$ENV_NAME'..."
    spack env create "$ENV_NAME" "$SPACK_YAML_DIR/spack.yaml"
fi

spack env activate "$ENV_NAME"

# 3. Build Phase
echo "Starting build (Concretize & Install)..."
spack concretize -f
spack install

if [ $? -ne 0 ]; then
    echo "❌ Spack installation failed!"
    exit 1
fi

# 4. Registration Phase
echo "Registering Jupyter Kernel..."
Rscript -e "IRkernel::installspec(name='$KERNEL_NAME', displayname='$DISPLAY_NAME', user=TRUE)"

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ R Kernel installation complete!"
    echo "   Use '$DISPLAY_NAME' in Jupyter."
    echo ""
else
    echo "❌ Kernel registration failed!"
    exit 1
fi
