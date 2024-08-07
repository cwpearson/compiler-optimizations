#! /bin/bash

set -eou pipefail

ROOT="$1"
shift
CXX_FLAGS="$@"

mkdir -p $ROOT
rm -rf $ROOT/*.log "$ROOT/trace" "$ROOT/perf"

date |& tee $ROOT/date.log
lscpu |& tee $ROOT/lscpu.log
cat /etc/os-release |& tee $ROOT/os_release.log
uname -a |& tee $ROOT/uname_a.log
cmake --version |& tee $ROOT/cmake_version.log
"${CXX}" --version |& tee $ROOT/cxx_version.log

export KOKKOS_SRC=kokkos
export KERNELS_SRC=kernels
export KOKKOS_BUILD=$ROOT/kokkos-build
export KOKKOS_INSTALL=$ROOT/kokkos-install
export KERNELS_BUILD=$ROOT/kernels-build

# Make sure source is available
git clone --branch 4.3.01 --depth 1 https://github.com/kokkos/kokkos.git $KOKKOS_SRC || true
git clone --branch 4.3.01 --depth 1 https://github.com/kokkos/kokkos-kernels.git $KERNELS_SRC || true
(cd $KOKKOS_SRC; git rev-parse HEAD | grep 6ecdf605e0f7639adec599d25cf0e206d7b8f9f5)
(cd $KERNELS_SRC; git rev-parse HEAD | grep d1a91b8a1f3aa4a972d7ff198bce73ec3248f641)

# build and install Release Kokkos
rm -rf $KOKKOS_BUILD
cmake -S $KOKKOS_SRC -B $KOKKOS_BUILD \
 -DCMAKE_INSTALL_PREFIX=$KOKKOS_INSTALL \
 -DCMAKE_BUILD_TYPE=Release \
 -DCMAKE_CXX_COMPILER="${CXX}" \
 -DKokkos_ENABLE_SERIAL=ON
nice -n20 cmake --build $KOKKOS_BUILD --target install --parallel $(nproc)
rm -rf $KOKKOS_BUILD

# Build Kokkos Kernels perf tests
rm -rf $KERNELS_BUILD
cmake -S $KERNELS_SRC -B $KERNELS_BUILD \
-DKokkos_ROOT=$KOKKOS_INSTALL \
-DCMAKE_CXX_COMPILER="${CXX}" \
-DCMAKE_CXX_FLAGS="$CXX_FLAGS" \
-DKokkosKernels_ENABLE_TESTS=ON \
-DKokkosKernels_ENABLE_PERFTESTS=ON \
-DKokkosKernels_ENABLE_BENCHMARK=ON
nice -n20 cmake --build $KERNELS_BUILD/perf_test --parallel $(nproc) |& tee $ROOT/build_perf.log
mv "$KERNELS_BUILD/perf_test" "$ROOT/perf"

# Run Kokkos Kernels perf tests
$ROOT/perf/sparse/KokkosKernels_sparse_spmv_benchmark \
  --benchmark_out_format=csv \
  --benchmark_out=$ROOT/sparse_spmv.csv \
  --benchmark_repetitions=5 \
  --benchmark_report_aggregates_only=true \
  --benchmark_display_aggregates_only=true

# Build Kokkos Kernels with ftime-trace
rm -rf $KERNELS_BUILD
cmake -S $KERNELS_SRC -B $KERNELS_BUILD \
-DKokkos_ROOT=$KOKKOS_INSTALL \
-DCMAKE_CXX_COMPILER="${CXX}" \
-DCMAKE_CXX_FLAGS="$CXX_FLAGS -ftime-trace"
VERBOSE=1 time cmake --build $KERNELS_BUILD |& tee $ROOT/build_trace.log
mkdir -p "$ROOT/trace"
for trace in $(find $KERNELS_BUILD -name "*.json"); do
  mv "$trace" "$ROOT/trace/."
done

# Builds to get timing
for b in $(seq 0 3); do
  rm -rf $KERNELS_BUILD
  cmake -S $KERNELS_SRC -B $KERNELS_BUILD \
    -DKokkos_ROOT=$KOKKOS_INSTALL \
    -DCMAKE_CXX_COMPILER="${CXX}" \
    -DCMAKE_CXX_FLAGS="$CXX_FLAGS"

  VERBOSE=1 time taskset -c 2 cmake --build $KERNELS_BUILD |& tee $ROOT/build_$b.log

  if [ ! -e $ROOT/du.log ]; then
    du $KERNELS_BUILD/libkokkoskernels.a > $ROOT/du.log
  fi

  rm -rf $KERNELS_BUILD
done

rm -rf $KOKKOS_INSTALL
