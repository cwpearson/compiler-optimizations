#! /bin/bash

set -eou pipefail

if [ ! -f $JOB_ROOT/01.COMPLETED ]; then
  $JOB_ROOT/perf/sparse/KokkosKernels_sparse_spmv_benchmark \
    --benchmark_out_format=csv \
    --benchmark_out=$JOB_ROOT/sparse_spmv.csv \
    --benchmark_repetitions=5 \
    --benchmark_report_aggregates_only=true \
    --benchmark_display_aggregates_only=true \
  && touch $JOB_ROOT/01.COMPLETED
fi

if [ ! -f $JOB_ROOT/02.COMPLETED ]; then
  if ! md5sum $MACHINE_ROOT/ifiss_mat/ifiss_mat.mtx | grep 7910557c9fbc815329a3f2bbe52dc590; then
    wget -L --continue \
      https://suitesparse-collection-website.herokuapp.com/MM/Embree/ifiss_mat.tar.gz \
      -O $MACHINE_ROOT/ifiss_mat.tar.gz
    tar -C "$MACHINE_ROOT" -xf "$MACHINE_ROOT/ifiss_mat.tar.gz"
  fi
  $JOB_ROOT/perf/sparse/sparse_spgemm \
    --amtx $MACHINE_ROOT/ifiss_mat/ifiss_mat.mtx \
    | tee sparse_spgemm_ifiss_mat.txt
  touch $JOB_ROOT/02.COMPLETED
fi

if [ ! -f $JOB_ROOT/03.COMPLETED ]; then
  $JOB_ROOT/perf/blas/blas3/KokkosBlas3_gemm_perf_test \
    | tee KokkosBlas3_gemm_perf_test.txt
  touch $JOB_ROOT/03.COMPLETED
fi
