import os
import pandas as pd
import shutil
import glob

# --- CONFIGURATION ---
CHECKM_DIR = "/home/marcos/PRJEB59406/checkm_results"
BINS_DIR = "/home/marcos/PRJEB59406/MetaBAT2_bins"
OUTPUT_DIR = "/home/marcos/PRJEB59406/filtered_bins_high_quality"

# Quality Thresholds (MIMAG Medium)
MIN_COMP = 50.0
MAX_CONT = 10.0

# ---------------------
os.makedirs(OUTPUT_DIR, exist_ok=True)
print(f"--- Filtering: Completeness >= {MIN_COMP}%, Contamination <= {MAX_CONT}% ---")

tables = glob.glob(f"{CHECKM_DIR}/*/quality_table.tsv")
total_copied = 0

for table in tables:
    try:
        # 1. Load Data
        df = pd.read_csv(table, sep="\t")
        sample_name = os.path.basename(os.path.dirname(table))
        
        # 2. Filter Bins
        good_bins = df[
            (df['Completeness'] >= MIN_COMP) & 
            (df['Contamination'] <= MAX_CONT)
        ]
        
        if good_bins.empty:
            continue

        print(f"Processing {sample_name}: {len(good_bins)} bins to copy.")
        
        # 3. Find and Copy Files
        for bin_id in good_bins['Bin Id']:
            # Search for bin file recursively inside sample folder
            search_path = f"{BINS_DIR}/{sample_name}/**/{bin_id}.fa"
            found = glob.glob(search_path, recursive=True)
            
            if found:
                src = found[0]
                dst = os.path.join(OUTPUT_DIR, f"{sample_name}_{bin_id}.fa")
                shutil.copy2(src, dst)
                total_copied += 1
            else:
                print(f"  Warning: File not found for {bin_id}")

    except Exception as e:
        print(f"Error in {sample_name}: {e}")

print("------------------------------------------------")
print(f"DONE! {total_copied} bins copied to:\n{OUTPUT_DIR}")
