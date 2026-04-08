import os
import glob
import ast
import numpy as np
import pandas as pd
from scipy.stats import gmean

# --- Configuration ---
ROOT_DIR = "/temporario2/17404478/PRJNA46333/assay"
CHECKM_DIR = os.path.join(ROOT_DIR, "checkm_results")
COVERM_FILE = os.path.join(ROOT_DIR, "coverm_results/mag_abundance.tsv")
OUTPUT_FILE = os.path.join(ROOT_DIR, "global_master_table_FINAL.csv")

# Quality Thresholds (MIMAG Medium Quality)
MIN_COMP = 50.0
MAX_CONT = 10.0

def calculate_clr(series):
    """Calculates Centered Log-Ratio (CLR) with a pseudo-count of 1."""
    counts = series + 1
    return np.log(counts / gmean(counts))

def get_genome_sizes(stats_file):
    """Extracts 'Genome size' from CheckM bin_stats_ext.tsv."""
    sizes = {}
    if not os.path.exists(stats_file):
        return sizes
    with open(stats_file, 'r') as f:
        for line in f:
            try:
                bin_id, stats_str = line.strip().split('\t')
                stats_dict = ast.literal_eval(stats_str)
                sizes[bin_id] = stats_dict.get('Genome size', 0)
            except (ValueError, SyntaxError):
                continue
    return sizes

# --- Load and Prepare Abundance Data ---
print("Loading abundance data...")
abundance_df = pd.read_csv(COVERM_FILE, sep="\t")
# Convert to long format (Tidy)
abundance_long = abundance_df.melt(
    id_vars="Genome", var_name="Sample_ID", value_name="Abundance"
).rename(columns={"Genome": "Bin Id"})

# --- Process Samples ---
print(f"Consolidating CheckM data from: {CHECKM_DIR}")
sample_dirs = sorted([d for d in glob.glob(os.path.join(CHECKM_DIR, "*")) if os.path.isdir(d)])
all_results = []

for s_path in sample_dirs:
    sample_name = os.path.basename(s_path)
    q_table = os.path.join(s_path, "quality_table.tsv")
    s_file = os.path.join(s_path, "storage", "bin_stats_ext.tsv")
    
    if not os.path.exists(q_table) or not os.path.exists(s_file):
        continue

    try:
        # Load quality data and filter immediately
        df = pd.read_csv(q_table, sep="\t")
        df = df[(df['Completeness'] >= MIN_COMP) & (df['Contamination'] <= MAX_CONT)].copy()
        
        if df.empty:
            continue

        # Add Metadata and Sizes
        df['Sample_ID'] = sample_name
        df['Genome_Size'] = df['Bin Id'].map(get_genome_sizes(s_file))
        
        # Merge with abundance
        df = df.merge(abundance_long, on=['Bin Id', 'Sample_ID'], how='left').fillna({'Abundance': 0})
        
        # Calculate CLR
        df['CLR_Abundance'] = calculate_clr(df['Abundance'])
        df['Fila_ID'] = "assay_PRJNA46333"
        
        all_results.append(df)
        print(f"  [OK] {sample_name}: {len(df)} bins.")

    except Exception as e:
        print(f"  [Error] Failed to process {sample_name}: {e}")

# --- Export Results ---
if all_results:
    final_df = pd.concat(all_results, ignore_index=True)
    
    # Reorder columns for clarity
    cols_priority = ['Fila_ID', 'Sample_ID', 'Bin Id', 'Completeness', 'Contamination', 'CLR_Abundance', 'Genome_Size']
    cols_other = [c for c in final_df.columns if c not in cols_priority]
    
    final_df[cols_priority + cols_other].to_csv(OUTPUT_FILE, index=False)
    print(f"\nSUCCESS! Table saved to: {OUTPUT_FILE}")
else:
    print("\nNo bins met the quality criteria.")