import re
from pathlib import Path
import numpy as np
import matplotlib.pyplot as plt
from scipy import stats
import sys

def extract_size(file_path):
    try:
        with file_path.open('r') as f:
            content = f.read()
            match = re.search(r'(\d+)', content)
            if match:
                return float(match.group(1))
    except FileNotFoundError:
        print(f"skip {file_path}")
    return None

def process_directory(directory):
    print(directory)
    time = extract_size(directory / 'du.log')
    if time is not None:
        return time
    return None

def analyze_directories(base_paths: list[Path]):
    results = {}
    for dir_path in base_paths:
        if dir_path.is_dir():
            times = process_directory(dir_path)
            if times:
                mean = np.mean(times)
                results[dir_path.name] = mean
    return results

def create_bar_graph(results):
    directories = list(results.keys())
    means = [result for result in results.values()]

    plt.figure(figsize=(12, 6))
    plt.bar(directories, means, capsize=5)
    plt.xlabel('Configuration')
    plt.ylabel('Library Size [KiB]')
    plt.title('Library Size by Configuration')
    plt.xticks(rotation=45, ha='right')
    plt.tight_layout()
    plt.savefig('library_sizes.png')
    plt.show()

# Main execution


results = analyze_directories([Path(x) for x in sys.argv[1:]])
create_bar_graph(results)