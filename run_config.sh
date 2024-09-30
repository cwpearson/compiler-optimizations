#! /bin/bash

set -eou pipefail

MACHINE="$1"
ENV="$2"
CONFIG="$3"

if [ -f machines/$MACHINE/machine ]; then
  echo . machines/$MACHINE/machine
  . machines/$MACHINE/machine
else
  echo . machines/common/machine
  . machines/common/machine
fi

export KOKKOS_SRC="$MACHINE_ROOT/kokkos"
export KERNELS_SRC="$MACHINE_ROOT/kernels"
export JOB_ROOT="$MACHINE_ROOT/${ENV}_$CONFIG"
export KOKKOS_BUILD="$JOB_ROOT/kokkos-build"
export KOKKOS_INSTALL="$JOB_ROOT/kokkos-install"
export KERNELS_BUILD="$JOB_ROOT/kernels-build"

mkdir -p $JOB_ROOT
rm -rf $JOB_ROOT/*.log "$JOB_ROOT/perf"

echo . machines/$MACHINE/envs/$ENV
. machines/$MACHINE/envs/$ENV

echo . configs/$CONFIG
. configs/$CONFIG

if [ -f machines/$MACHINE/sysinfo ]; then
  echo . machines/$MACHINE/sysinfo
  . machines/$MACHINE/sysinfo
else
  echo . machines/common/sysinfo
  . machines/common/sysinfo
fi


machine_sysinfo

# Make sure source is available
git clone --branch 4.3.01 --depth 1 https://github.com/kokkos/kokkos.git $KOKKOS_SRC || true
git clone --branch 4.3.01 --depth 1 https://github.com/kokkos/kokkos-kernels.git $KERNELS_SRC || true
(cd $KOKKOS_SRC; git rev-parse HEAD | grep 6ecdf605e0f7639adec599d25cf0e206d7b8f9f5)
(cd $KERNELS_SRC; git rev-parse HEAD | grep d1a91b8a1f3aa4a972d7ff198bce73ec3248f641)

# build and install Kokkos
if [ ! -f $KOKKOS_INSTALL/COMPLETED ]; then
  rm -rf "$KOKKOS_BUILD" "$KOKKOS_INSTALL"
  cmake -S $KOKKOS_SRC -B $KOKKOS_BUILD \
   "${KOKKOS_CONFIG_OPTS[@]}" \
   -DCMAKE_INSTALL_PREFIX=$KOKKOS_INSTALL \
   -DCMAKE_CXX_COMPILER="${CXX}"
  nice -n20 cmake --build $KOKKOS_BUILD --target install --parallel $(nproc)
  touch "$KOKKOS_INSTALL/COMPLETED"
  rm -rf $KOKKOS_BUILD
else
  echo $KOKKOS_INSTALL already complete!
fi

# Build Kokkos Kernels perf tests
if [ ! -f "$JOB_ROOT/perf/COMPLETED" ]; then
  rm -rf $KERNELS_BUILD
  cmake -S $KERNELS_SRC -B $KERNELS_BUILD \
  "${KERNELS_CONFIG_OPTS[@]}" \
  -DKokkos_ROOT=$KOKKOS_INSTALL \
  -DCMAKE_CXX_COMPILER="${CXX}" \
  -DKokkosKernels_ENABLE_TESTS=ON \
  -DKokkosKernels_ENABLE_PERFTESTS=ON \
  -DKokkosKernels_ENABLE_BENCHMARK=ON
  nice -n20 cmake --build $KERNELS_BUILD/perf_test --parallel $(nproc) |& tee $JOB_ROOT/build_perf.log
  mv "$KERNELS_BUILD/perf_test" "$JOB_ROOT/perf"
  touch "$JOB_ROOT/perf/COMPLETED"
else
  echo "$JOB_ROOT/perf" already exists!
fi

# Run Kokkos Kernels perf tests
machines/$MACHINE/perf_tests.sh

# Repeated Builds to get compile time
if [ ! -f "$JOB_ROOT/COMPILE_TIMES_COMPLETED" ]; then
  rm -rf $KERNELS_BUILD
  cmake -S $KERNELS_SRC -B $KERNELS_BUILD \
    "${KERNELS_CONFIG_OPTS[@]}" \
    -DKokkos_ROOT=$KOKKOS_INSTALL \
    -DCMAKE_CXX_COMPILER="${CXX}"
  for b in $(seq 0 3); do
    VERBOSE=1 time taskset -c 2 cmake --build $KERNELS_BUILD |& tee $JOB_ROOT/build_$b.log
  
    if [ ! -e $JOB_ROOT/du.log ]; then
      du $KERNELS_BUILD/libkokkoskernels.a > $JOB_ROOT/du.log
    fi
  
    cmake --build $KERNELS_BUILD --target clean
  done
  touch "$JOB_ROOT/COMPILE_TIMES_COMPLETED"
else
  echo "$JOB_ROOT/COMPILE_TIMES_COMPLETED" already exists!
fi
