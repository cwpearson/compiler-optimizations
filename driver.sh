#! /bin/bash

set -eou pipefail


configs=(

  # clang man pages only describe what -march does, so stick with that I guess
  "llvm-14.0.6 -O1"
  "llvm-14.0.6 -O1 -ffast-math"
  "llvm-14.0.6 -O1 -ffast-math -march=native"
  "llvm-14.0.6 -Os"
  "llvm-14.0.6 -Os -ffast-math"
  "llvm-14.0.6 -Os -ffast-math -march=native"
  "llvm-14.0.6 -O2"
  "llvm-14.0.6 -O2 -ffast-math"
  "llvm-14.0.6 -O2 -ffast-math -march=native"
  "llvm-14.0.6 -O3"
  "llvm-14.0.6 -O3 -ffast-math"
  "llvm-14.0.6 -O3 -ffast-math -march=native"
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

  # for gcc, march implies mtune
  "gcc-9.5.0 -O1"
  "gcc-9.5.0 -O1 -fast-math"
  "gcc-9.5.0 -O1 -fast-math -march=native"
  "gcc-9.5.0 -O2"
  "gcc-9.5.0 -O2 -fast-math"
  "gcc-9.5.0 -O2 -fast-math -march=native"
  "gcc-9.5.0 -O3"
  "gcc-9.5.0 -O3 -fast-math"
  "gcc-9.5.0 -O3 -fast-math -march=native"
  "gcc-9.5.0 -Os"
  "gcc-9.5.0 -Os -fast-math"
  "gcc-9.5.0 -Os -fast-math -march=native"

  "gcc-10.4.0 -O1"
  "gcc-10.4.0 -O1 -fast-math"
  "gcc-10.4.0 -O1 -fast-math -march=native"
  "gcc-10.4.0 -O2"
  "gcc-10.4.0 -O2 -fast-math"
  "gcc-10.4.0 -O2 -fast-math -march=native"
  "gcc-10.4.0 -O3"
  "gcc-10.4.0 -O3 -fast-math"
  "gcc-10.4.0 -O3 -fast-math -march=native"
  "gcc-10.4.0 -Os"
  "gcc-10.4.0 -Os -fast-math"
  "gcc-10.4.0 -Os -fast-math -march=native"

  "gcc-11.3.0 -O1"
  "gcc-11.3.0 -O1 -fast-math"
  "gcc-11.3.0 -O1 -fast-math -march=native"
  "gcc-11.3.0 -O2"
  "gcc-11.3.0 -O2 -fast-math"
  "gcc-11.3.0 -O2 -fast-math -march=native"
  "gcc-11.3.0 -O3"
  "gcc-11.3.0 -O3 -fast-math"
  "gcc-11.3.0 -O3 -fast-math -march=native"
  "gcc-11.3.0 -Os"
  "gcc-11.3.0 -Os -fast-math"
  "gcc-11.3.0 -Os -fast-math -march=native"

  "gcc-12.3.0 -O1"
  "gcc-12.3.0 -O1 -fast-math"
  "gcc-12.3.0 -O1 -fast-math -march=native"
  "gcc-12.3.0 -O2"
  "gcc-12.3.0 -O2 -fast-math"
  "gcc-12.3.0 -O2 -fast-math -march=native"
  "gcc-12.3.0 -O3"
  "gcc-12.3.0 -O3 -fast-math"
  "gcc-12.3.0 -O3 -fast-math -march=native"
  "gcc-12.3.0 -Os"
  "gcc-12.3.0 -Os -fast-math"
  "gcc-12.3.0 -Os -fast-math -march=native"

  "gcc-13.1.0 -O1"
  "gcc-13.1.0 -O1 -fast-math"
  "gcc-13.1.0 -O1 -fast-math -march=native"
  "gcc-13.1.0 -O2"
  "gcc-13.1.0 -O2 -fast-math"
  "gcc-13.1.0 -O2 -fast-math -march=native"
  "gcc-13.1.0 -O3"
  "gcc-13.1.0 -O3 -fast-math"
  "gcc-13.1.0 -O3 -fast-math -march=native"
  "gcc-13.1.0 -Os"
  "gcc-13.1.0 -Os -fast-math"
  "gcc-13.1.0 -Os -fast-math -march=native"
)

for cfg in "${configs[@]}"; do

  compiler=$(echo $cfg | cut -f1 -d' ')
  flags=$(echo $cfg | cut -f2- -d' ')

  echo $compiler $flags

  ./"${compiler}".sh "$flags"
done

