#! /bin/bash

set -eou pipefail

CXX_FLAGS="$@"

# replace spaces with underscores
CXX_FLAGS_NAME="${CXX_FLAGS// /_}"

export ROOT="llvm1406_${CXX_FLAGS_NAME}"

spack load llvm@14.0.6 || spack install llvm@14.0.6
spack load llvm@14.0.6
export CXX="clang++"

./run.sh "$ROOT" "$CXX_FLAGS"
