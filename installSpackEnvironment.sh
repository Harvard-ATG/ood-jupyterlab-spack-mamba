#!/bin/bash
# Install packages in a spack environment given in the first argument

# Activate spack
. /shared/spack/share/spack/setup-env.sh

# Activate given environment
spack env activate $1

# Install packages
spack install
