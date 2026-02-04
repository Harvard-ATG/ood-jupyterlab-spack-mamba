#!/bin/bash
#SBATCH --job-name=r-kernel-build
#SBATCH --output=r-kernel-%j.out
#SBATCH --error=r-kernel-%j.err
#SBATCH --time=01:30:00
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4
#SBATCH --mem=16G

# Created with help of Gemini 3.0 Pro AI Model

# -------------------------------------------------------------------------
# SCRIPT: R Kernel Builder (Universal)
# -------------------------------------------------------------------------
# Purpose: Builds a Spack R environment and generates a kernel spec for Jupyter.
# Usage:   sbatch installRKernel.sh -p <TARGET_LOCATION>
# -------------------------------------------------------------------------

# Defaults
SPACK_YAML_DIR="./spack-environment" # Directory containing spack.yaml
ENV_NAME="r-kernel-env"              # Name of the internal Spack env
KERNEL_NAME="ir_kernel"              # Internal ID for Jupyter
DISPLAY_NAME="R (Spack)"             # What the user sees in the menu
TARGET_PREFIX=""                     # Where to register the kernel

usage() {
    echo "Usage: sbatch installRKernel.sh -p <TARGET_PREFIX> [options]"
    echo "  -p DIR    Target Destination (REQUIRED)"
    echo "            (e.g., a staging folder or a live Mamba env path)"
    echo "  -d DIR    Source dir for spack.yaml (default: $SPACK_YAML_DIR)"
    echo "  -n NAME   Spack Env Name (default: $ENV_NAME)"
    echo "  -l LABEL  Display Name (default: $DISPLAY_NAME)"
    exit 1
}

# Parse Args
while getopts "p:d:n:k:l:h" opt; do
    case $opt in
        p) TARGET_PREFIX="$OPTARG" ;;
        d) SPACK_YAML_DIR="$OPTARG" ;;
        n) ENV_NAME="$OPTARG" ;;
        l) DISPLAY_NAME="$OPTARG" ;;
        h) usage ;;
        *) usage ;;
    esac
done

# Validation
if [ -z "$TARGET_PREFIX" ]; then
    echo "❌ Error: You must specify a target prefix with -p."
    echo "   Use a staging directory (safest) or a live Mamba env path."
    exit 1
fi

if [ ! -d "$TARGET_PREFIX" ]; then
    echo "❌ Error: Target path does not exist: $TARGET_PREFIX"
    echo "   Please create it first (e.g., mkdir -p ./staging/gpu)"
    exit 1
fi

echo "================================================="
echo " Building R Kernel (Sidecar)"
echo "-------------------------------------------------"
echo " Spack Env:   $ENV_NAME"
echo " Target Dest: $TARGET_PREFIX"
echo " Label:       $DISPLAY_NAME"
echo "================================================="

# 1. Load Spack
source /shared/spack/share/spack/setup-env.sh

# 2. Activate/Create Spack Env
# Detect Configuration File (.yaml or .yml)
if [ -f "$SPACK_YAML_DIR/spack.yaml" ]; then
    CONFIG_FILE="$SPACK_YAML_DIR/spack.yaml"
elif [ -f "$SPACK_YAML_DIR/spack.yml" ]; then
    CONFIG_FILE="$SPACK_YAML_DIR/spack.yml"
else
    echo "❌ Error: No spack.yaml or spack.yml found in directory: $SPACK_YAML_DIR"
    exit 1
fi

if spack env list | grep -q "^${ENV_NAME}$"; then
    echo "-> Activating existing Spack environment..."
    spack env activate "$ENV_NAME"
else
    echo "-> Creating new Spack environment from $CONFIG_FILE..."
    spack env create "$ENV_NAME" "$CONFIG_FILE"
    spack env activate "$ENV_NAME"
fi

# 3. Install Software (The Heavy Lifting)
echo "-> Concretizing and Installing..."
spack concretize -f
spack install

# 4. Register Kernel (The Bridge)
# -------------------------------------------------------------------------
# NOTE: This step generates the 'kernel.json' file.
# It tells Jupyter: "When the user clicks '$DISPLAY_NAME', run the R executable
# located inside this Spack environment."
# -------------------------------------------------------------------------
echo "-> Registering kernel to designated location: $TARGET_PREFIX"

Rscript -e "IRkernel::installspec(name='$KERNEL_NAME', displayname='$DISPLAY_NAME', user=FALSE, prefix='$TARGET_PREFIX')"

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Success! Kernel spec (kernel.json) created at:"
    echo "   $TARGET_PREFIX/share/jupyter/kernels/$KERNEL_NAME/"
    echo ""
else
    echo "❌ Registration failed."
    exit 1
fi