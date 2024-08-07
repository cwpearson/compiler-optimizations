#! /bin/bash

set -eou pipefail

CXX_FLAGS="$@"

# replace spaces with underscores
CXX_FLAGS_NAME="${CXX_FLAGS// /_}"

export ROOT="gcc@9.5.0_${CXX_FLAGS_NAME}"

spack load gcc@9.5.0 || spack install gcc@9.5.0
spack load gcc@9.5.0
export CXX="g++"

./run.sh "$ROOT" "$CXX_FLAGS"
