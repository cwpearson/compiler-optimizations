import re
from pathlib import Path
import numpy as np
import matplotlib.pyplot as plt
from scipy import stats
import sys
import csv
from dataclasses import dataclass
from datetime import datetime

def by_compiler_version(item: str) -> tuple[str, list[int]]:
    try:
        compiler, version, config = re.match(r'^(.+)@([\d.]+)_(.+)$', item).groups()
        version_parts = version.split('.')
        return (compiler, [int(part) for part in version_parts])
    except AttributeError:
        # If the string doesn't match the expected format,
        # return a tuple that will sort after valid entries
        return ('', [])

def extract_time(file_path):
    with file_path.open('r') as f:
        content = f.read()
        match = re.search(r'(\d+\.\d+)user', content)
        if match:
            return float(match.group(1))
    return None

@dataclass
class Perf:
    spmv_mean: float
    spmv_stddev: float
    spgemm_total_mean: float
    spgemm_numeric_mean: float
    spgemm_symbolic_mean: float
    spgemm_total_stddev: float
    spgemm_numeric_stddev: float
    spgemm_symbolic_stddev: float
    gemm_ll_ll_mean: float
    gemm_ll_lr_mean: float
    gemm_lr_ll_mean: float
    gemm_lr_lr_mean: float

def process_directory(directory) -> Perf:
    print(f"process {directory}")

    ## parse spmv
    spmv_mean=None
    spmv_stddev=None
    try:
        with open(directory / "sparse_spmv.csv", 'r') as f:
            reader = csv.reader(f, delimiter=',', quotechar='"')
            mean, stddev = None, None
            for row in reader:
                if row[0] == "KokkosSparse_spmv/n:1000000/nv:10/real_time_mean":
                    mean = float(row[2])
                elif row[0] == "KokkosSparse_spmv/n:1000000/nv:10/real_time_stddev":
                    stddev = float(row[2])
            if mean is not None and stddev is not None:
                spmv_mean = mean
                spmv_stddev = stddev
    except FileNotFoundError:
        pass

    ## try to parse spgemm
    spgemm_total_mean=None
    spgemm_symbolic_mean=None
    spgemm_numeric_mean=None
    spgemm_total_stddev=None
    spgemm_symbolic_stddev=None
    spgemm_numeric_stddev=None
    try:
        with open(directory / "sparse_spgemm_ifiss_mat.txt", 'r') as f:

            totals = []
            symbolics = []
            numerics = []
            for line in f.readlines():
                # like mm_time:0.531497 symbolic_time:0.0732346 numeric_time:0.458262
                match = re.search(r'mm_time:(\d+\.\d+) symbolic_time:(\d+\.\d+) numeric_time:(\d+\.\d+)', line)
                if match:
                    totals.append(float(match.group(1)))
                    symbolics.append(float(match.group(2)))
                    numerics.append(float(match.group(3)))
            spgemm_total_mean, spgemm_total_stddev = np.mean(totals), np.std(totals)
            spgemm_symbolic_mean, spgemm_symbolic_stddev = np.mean(symbolics), np.std(symbolics)
            spgemm_numeric_mean, spgemm_numeric_stddev = np.mean(numerics), np.std(numerics)
    except FileNotFoundError:
        pass

    ## try to parse gemm
    gemm_ll_ll_mean = None
    gemm_ll_lr_mean = None
    gemm_lr_ll_mean = None
    gemm_lr_lr_mean = None
    try:
        with open(directory / "KokkosBlas3_gemm_perf_test.txt", 'r') as f:
            for line in f.readlines():
                # Running: A LayoutRight, B LayoutRight: Avg GEMM FLOP/s: 5.253e+09 --- Avg time: 0.380752
                match = re.search(r'Running: A (.*), B (.*): Avg GEMM FLOP/s:.* --- Avg time: (\d+\.\d+)', line)
                if match:
                    a_layout = match.group(1).strip()
                    b_layout = match.group(2).strip()
                    time = float(match.group(3))
                    if a_layout == "LayoutLeft" and b_layout == "LayoutLeft":
                        gemm_ll_ll_mean = time
                    elif a_layout == "LayoutLeft" and b_layout == "LayoutRight":
                        gemm_ll_lr_mean = time
                    elif a_layout == "LayoutRight" and b_layout == "LayoutLeft":
                        gemm_lr_ll_mean = time
                    elif a_layout == "LayoutRight" and b_layout == "LayoutRight":
                        gemm_lr_lr_mean = time
    except FileNotFoundError:
        pass

    return Perf(spmv_mean, spmv_stddev,
                spgemm_total_mean, spgemm_numeric_mean, spgemm_symbolic_mean,
                spgemm_total_stddev, spgemm_numeric_stddev, spgemm_symbolic_stddev,
                gemm_ll_ll_mean, gemm_ll_lr_mean, gemm_lr_ll_mean, gemm_lr_lr_mean)

def analyze_directories(base_paths: list[Path]) -> dict[str, Perf]:
    results = {}
    for dir_path in base_paths:
        if dir_path.is_dir():
            perf = process_directory(dir_path)
            results[dir_path.name] = perf
    return results

def create_bar_graphs(results: dict[str, Perf]):

    formatted_datetime = datetime.now().strftime("%m-%d-%Y %I:%M%p")

    # parse SpMV results
    spmv_x = []
    spmv_y = []
    spmv_yerr = []
    for dir in sorted(results.keys(), key=by_compiler_version):
        perf = results[dir]
        if perf.spmv_mean is not None and perf.spmv_stddev is not None:
            spmv_x.append(dir)
            spmv_y.append(perf.spmv_mean)
            spmv_yerr.append(perf.spmv_stddev)




    plt.figure(figsize=(12, 6))
    plt.bar(spmv_x, spmv_y, yerr=spmv_yerr, capsize=5)
    plt.xlabel('Configuration')
    plt.ylabel('SpMV MV Time [s]')
    plt.title(f'SpMV MV Time by Configuration {formatted_datetime}')
    plt.xticks(rotation=45, ha='right')
    plt.tight_layout()
    # Add vertical lines after every fourth group
    for i in range(4, len(spmv_x), 4):
        plt.axvline(x=i - 0.5, color='gray', linestyle='--', alpha=0.7)
    plt.savefig('perf_spmv_mv.png')

    ## plot SpGEMM
    spgemm_x = []
    spgemm_numeric_y = []
    spgemm_numeric_yerr = []
    spgemm_symbolic_y = []
    spgemm_symbolic_yerr = []
    for dir in sorted(results.keys(), key=by_compiler_version):
        perf = results[dir]
        if perf.spgemm_numeric_mean is not None and perf.spgemm_numeric_stddev is not None and perf.spgemm_symbolic_mean is not None and perf.spgemm_symbolic_stddev is not None:
            spgemm_x.append(dir)
            spgemm_numeric_y.append(perf.spgemm_numeric_mean)
            spgemm_numeric_yerr.append(perf.spgemm_numeric_stddev)
            spgemm_symbolic_y.append(perf.spgemm_symbolic_mean)
            spgemm_symbolic_yerr.append(perf.spgemm_symbolic_stddev)

    fig, ax = plt.subplots(figsize=(12, 6))
    width = 0.35
    x = np.arange(len(spgemm_x))
    bars1 = ax.bar(x - width/2, spgemm_symbolic_y, width, label='Symbolic', yerr=spgemm_symbolic_yerr, capsize=5)
    bars2 = ax.bar(x + width/2, spgemm_numeric_y, width, label='Numeric', yerr=spgemm_numeric_yerr, capsize=5)
    ax.set_ylabel('SpGEMM Time [s]')
    ax.set_xlabel('Configuration')
    ax.set_title(f'SpGEMM Time by Configuration ({formatted_datetime})')
    ax.set_xticks(x)
    ax.set_xticklabels(spgemm_x, rotation=45, ha='right')
    ax.legend()
    # Add vertical lines after every fourth group
    for i in range(4, len(spgemm_x), 4):
        ax.axvline(x=i - 0.5, color='gray', linestyle='--', alpha=0.7)
    plt.tight_layout()
    plt.savefig('perf_spgemm.png')

    ## plot GEMM
    gemm_x = []
    gemm_ll_ll_y = []
    gemm_ll_lr_y = []
    gemm_lr_ll_y = []
    gemm_lr_lr_y = []
    for dir in sorted(results.keys(), key=by_compiler_version):
        perf = results[dir]
        if perf.gemm_ll_ll_mean is not None and perf.gemm_ll_lr_mean is not None and perf.gemm_lr_ll_mean is not None and perf.gemm_lr_lr_mean is not None:
            gemm_x.append(dir)
            gemm_ll_ll_y.append(perf.gemm_ll_ll_mean)
            gemm_ll_lr_y.append(perf.gemm_ll_lr_mean)
            gemm_lr_ll_y.append(perf.gemm_lr_ll_mean)
            gemm_lr_lr_y.append(perf.gemm_lr_lr_mean) 

    fig, ax = plt.subplots(figsize=(12, 6))
    width = 0.2
    x = np.arange(len(gemm_x))
    ax.bar(x - 1.5*width, gemm_ll_ll_y, width, label='LL x LL', capsize=5)
    ax.bar(x - 0.5*width, gemm_ll_lr_y, width, label='LL x LR', capsize=5)
    ax.bar(x + 0.5*width, gemm_lr_ll_y, width, label='LR x LL', capsize=5)
    ax.bar(x + 1.5*width, gemm_lr_lr_y, width, label='LR x LR', capsize=5)
    ax.set_ylabel('GEMM Time [s]')
    ax.set_xlabel('Configuration')
    ax.set_title(f'GEMM Time by Configuration ({formatted_datetime})')
    ax.set_xticks(x)
    ax.set_xticklabels(gemm_x, rotation=45, ha='right')
    ax.legend()
    # Add vertical lines after every fourth group
    for i in range(4, len(gemm_x), 4):
        ax.axvline(x=i - 0.5, color='gray', linestyle='--', alpha=0.7)
    plt.tight_layout()
    plt.savefig('perf_gemm.png')

if __name__ == "__main__":
    results = analyze_directories([Path(x) for x in sys.argv[1:]])
    create_bar_graphs(results)