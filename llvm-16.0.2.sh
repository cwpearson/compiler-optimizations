#! /bin/bash

set -eou pipefail

CXX_FLAGS="$@"

# replace spaces with underscores
CXX_FLAGS_NAME="${CXX_FLAGS// /_}"

export ROOT="llvm1602_${CXX_FLAGS_NAME}"

spack load llvm@16.0.2 || spack install llvm@16.0.2
spack load llvm@16.0.2
export CXX="clang++"

./run.sh "$ROOT" "$CXX_FLAGS"
