import re
from pathlib import Path
import numpy as np
import matplotlib.pyplot as plt
from scipy import stats
import sys
import csv

def extract_time(file_path):
    with file_path.open('r') as f:
        content = f.read()
        match = re.search(r'(\d+\.\d+)user', content)
        if match:
            return float(match.group(1))
    return None

def process_directory(directory):
    print(f"process {directory}")
    times = []
    with open(directory / "sparse_spmv.csv", 'r') as f:
        reader = csv.reader(f, delimiter=',', quotechar='"')
        for row in reader:
            if row[0] == "KokkosSparse_spmv/n:1000000/nv:10/real_time":
                times.append(float(row[2]))
    return times

def analyze_directories(base_paths: list[Path]):
    results = {}
    for dir_path in base_paths:
        if dir_path.is_dir():
            times = process_directory(dir_path)
            if times:
                mean = np.mean(times)
                sem = stats.sem(times)
                results[dir_path.name] = (mean, sem)
    return results

def create_bar_graph(results):
    directories = list(results.keys())
    means = [result[0] for result in results.values()]
    errors = [result[1] for result in results.values()]

    plt.figure(figsize=(12, 6))
    plt.bar(directories, means, yerr=errors, capsize=5)
    plt.xlabel('Configuration')
    plt.ylabel('SpMV Time [s]')
    plt.title('SpMV Time by Configuration')
    plt.xticks(rotation=45, ha='right')
    plt.tight_layout()
    plt.savefig('spmv.png')
    plt.show()

# Main execution


results = analyze_directories([Path(x) for x in sys.argv[1:]])
create_bar_graph(results)