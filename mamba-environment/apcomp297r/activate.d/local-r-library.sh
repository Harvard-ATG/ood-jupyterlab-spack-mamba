#!/bin/bash
# Conda/mamba activation hook: runs automatically every time this environment
# is activated (see `etc/conda/activate.d` in the Conda docs). This env's R
# library is read-only to users, so give each user a writable, R-version-
# scoped personal library via R_LIBS_USER the first time they activate it.
R_VERSION=$(R --version | head -n1 | grep -oE '[0-9]+\.[0-9]+' | head -n1)
R_LIBS_USER_DIR="${HOME}/R/conda-library/${R_VERSION}"
mkdir -p "$R_LIBS_USER_DIR"
export R_LIBS_USER="$R_LIBS_USER_DIR"
