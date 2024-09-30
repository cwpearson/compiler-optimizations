#! /bin/bash

set -eou pipefail

if [ ! -f $JOB_ROOT/01.COMPLETED]; then
  $JOB_ROOT/perf/sparse/KokkosKernels_sparse_spmv_benchmark \
    --benchmark_out_format=csv \
    --benchmark_out=$JOB_ROOT/sparse_spmv.csv \
    --benchmark_repetitions=5 \
    --benchmark_report_aggregates_only=true \
    --benchmark_display_aggregates_only=true \
  && touch $JOB_ROOT/01.COMPLETED
fi