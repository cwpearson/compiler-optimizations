#! /bin/bash

set -eou pipefail

CXX_FLAGS="$@"

# replace spaces with underscores
CXX_FLAGS_NAME="${CXX_FLAGS// /_}"

export ROOT="llvm1507_${CXX_FLAGS_NAME}"

spack load llvm@15.0.7 || spack install llvm@15.0.7
spack load llvm@15.0.7
export CXX="clang++"

./run.sh "$ROOT" "$CXX_FLAGS"
