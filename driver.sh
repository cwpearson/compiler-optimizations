#! /bin/bash

set -eou pipefail


configs=(
  "llvm-14.0.6 -O1"
  "llvm-14.0.6 -O1 -ffast-math"
  "llvm-14.0.6 -O1 -ffast-math -march=native -mtune=native"
  "llvm-14.0.6 -Os"
  "llvm-14.0.6 -Os -ffast-math"
  "llvm-14.0.6 -Os -ffast-math -march=native -mtune=native"
  "llvm-14.0.6 -O2"
  "llvm-14.0.6 -O2 -ffast-math"
  "llvm-14.0.6 -O2 -ffast-math -march=native -mtune=native"
  "llvm-14.0.6 -O3"
  "llvm-14.0.6 -O3 -ffast-math"
  "llvm-14.0.6 -O3 -ffast-math -march=native -mtune=native"
  "llvm-15.0.7 -O1"
  "llvm-15.0.7 -O1 -ffast-math"
  "llvm-15.0.7 -O1 -ffast-math -mcpu=native"
  "llvm-15.0.7 -Os"
  "llvm-15.0.7 -Os -ffast-math"
  "llvm-15.0.7 -Os -ffast-math -mcpu=native"
  "llvm-15.0.7 -O2"
  "llvm-15.0.7 -O2 -ffast-math"
  "llvm-15.0.7 -O2 -ffast-math -mcpu=native"
  "llvm-15.0.7 -O3"
  "llvm-15.0.7 -O3 -ffast-math"
  "llvm-15.0.7 -O3 -ffast-math -mcpu=native"
  "llvm-16.0.2 -O1"
  "llvm-16.0.2 -O1 -ffast-math"
  "llvm-16.0.2 -O1 -ffast-math -mcpu=native"
  "llvm-16.0.2 -Os"
  "llvm-16.0.2 -Os -ffast-math"
  "llvm-16.0.2 -Os -ffast-math -mcpu=native"
  "llvm-16.0.2 -O2"
  "llvm-16.0.2 -O2 -ffast-math"
  "llvm-16.0.2 -O2 -ffast-math -mcpu=native"
  "llvm-16.0.2 -O3"
  "llvm-16.0.2 -O3 -ffast-math"
  "llvm-16.0.2 -O3 -ffast-math -mcpu=native"
)

for cfg in "${configs[@]}"; do

  compiler=$(echo $cfg | cut -f1 -d' ')
  flags=$(echo $cfg | cut -f2- -d' ')

  echo $compiler $flags

  ./"${compiler}".sh "$flags"
done

