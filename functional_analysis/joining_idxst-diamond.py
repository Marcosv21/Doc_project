import os
import pandas as pd

# --- PATH CONFIGURATION ---
BASE_DIR = "/home/marcos/PRJEB59406/compactados"
IDXSTATS_DIR = f"{BASE_DIR}/idxstats"
DIAMOND_DIR = f"{BASE_DIR}/diamond_results_filtrados"
OUTPUT_DIR = f"{BASE_DIR}/abundance_results"
SAMPLE_MAP = f"{BASE_DIR}/sample_map.csv"

# Output files
UNIFIED_FILE = f"{OUTPUT_DIR}/unified_abundance_table.tsv"
FINAL_FILE = f"{OUTPUT_DIR}/unified_abundance_with_groups.tsv"

os.makedirs(OUTPUT_DIR, exist_ok=True)

# --- FUNCTIONS ---

def load_idxstats(path):
    """Loads idxstats and calculates RPKM abundance."""
    try:
        # Read without header
        df = pd.read_csv(path, sep='\t', header=None, names=['CDS', 'Length', 'Mapped', 'Unmapped'])
        df = df[df['CDS'] != '*'] # Remove unmapped reads
        
        # Calculate RPKM
        total_mapped = df['Mapped'].sum()
        if total_mapped > 0:
            df['Abundance'] = (df['Mapped'] * 1e9) / (df['Length'] * total_mapped)
        else:
            df['Abundance'] = 0.0
            
        return df[['CDS', 'Abundance']]
    except Exception as e:
        print(f"   [Error] Reading idxstats: {e}")
        return None

def load_diamond(path):
    """Loads Diamond results and standardizes column names."""
    try:
        df = pd.read_csv(path, sep='\t')
        
        # Standardize column names
        if 'seqid' in df.columns:
            df.rename(columns={'seqid': 'CDS', 'sseqid': 'Protein'}, inplace=True)
        elif 'CDS' not in df.columns:
            # Fallback for files without header
            df = pd.read_csv(path, sep='\t', header=None)
            df = df.iloc[:, [0, 1]]
            df.columns = ['CDS', 'Protein']
            
        return df[['CDS', 'Protein']]
    except Exception as e:
        print(f"   [Error] Reading Diamond: {e}")
        return None

# --- MAIN PROCESSING ---

print("Starting data merger...")
all_samples = []
files = [f for f in os.listdir(IDXSTATS_DIR) if f.endswith(".idxstats.txt")]

if not files:
    print("Error: No .idxstats.txt files found.")
    exit()

# 1. Merge Idxstats + Diamond
for file in files:
    # Clean filename to get Sample ID
    sample_id = file.replace(".idxstats.txt", "").replace("_aligned_fna", "")
    
    idx_path = os.path.join(IDXSTATS_DIR, file)
    diamond_path = os.path.join(DIAMOND_DIR, f"{sample_id}_matches.tsv")
    
    if os.path.exists(diamond_path):
        df_idx = load_idxstats(idx_path)
        df_diamond = load_diamond(diamond_path)
        
        if df_idx is not None and df_diamond is not None:
            # Inner join: Keep only annotated genes
            df_merged = df_diamond.merge(df_idx, on='CDS', how='inner')
            df_merged['Sample'] = sample_id
            all_samples.append(df_merged)
            print(f"-> Processed: {sample_id} ({len(df_merged)} matches)")
    else:
        print(f"   [Warning] Missing Diamond file for: {sample_id}")

if not all_samples:
    print("Error: No data processed.")
    exit()

# Save intermediate file
final_df = pd.concat(all_samples, ignore_index=True)
final_df.to_csv(UNIFIED_FILE, sep='\t', index=False)
print(f"Saved unified table: {UNIFIED_FILE}")

# 2. Add Group Information
if os.path.exists(SAMPLE_MAP):
    try:
        # Auto-detect separator (comma or tab)
        df_map = pd.read_csv(SAMPLE_MAP, sep=None, engine='python')
        df_map.columns = df_map.columns.str.strip()
        
        # Smart column detection
        cols = df_map.columns
        col_id = next((c for c in ['run_accession', 'Run', 'Sample'] if c in cols), cols[0])
        col_group = next((c for c in ['Group', 'AMYLOID', 'Condition'] if c in cols), cols[-1])

        print(f"Mapping Groups: '{col_id}' -> '{col_group}'")

        # Prepare map
        df_clean_map = df_map[[col_id, col_group]].rename(columns={col_id: 'Sample', col_group: 'Group'})
        df_clean_map = df_clean_map.drop_duplicates(subset='Sample')

        # Final Merge
        df_final_grouped = final_df.merge(df_clean_map, on='Sample', how='left')
        df_final_grouped.to_csv(FINAL_FILE, sep='\t', index=False)
        print(f"Final table with groups saved: {FINAL_FILE}")
        
    except Exception as e:
        print(f"   [Error] Processing sample map: {e}")
else:
    print("   [Warning] Sample map not found. Skipping group addition.")