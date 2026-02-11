import os
import pandas as pd
import glob

# --- PATH CONFIGURATION ---
# Base directory where the 'functional' folder is located
BASE_PATH = "/home/marcos/PRJEB59406/ORGANIZED_RESULTS"
FUNCTIONAL_DIR = os.path.join(BASE_PATH, "functional")

# The output files will be saved in the main functional folder
UNIFIED_FILE = os.path.join(FUNCTIONAL_DIR, "unified_abundance_table.tsv")
FINAL_FILE = os.path.join(FUNCTIONAL_DIR, "unified_abundance_with_groups.tsv")
SAMPLE_MAP = os.path.join(FUNCTIONAL_DIR, "sample_map.csv") # Check if it is .csv or .csv.gz

# --- FUNCTIONS ---

def load_idxstats(path):
    """Loads idxstats and calculates RPKM abundance."""
    try:
        # Read without header
        df = pd.read_csv(path, sep='\t', header=None, names=['CDS', 'Length', 'Mapped', 'Unmapped'])
        df = df[df['CDS'] != '*'].copy() # Remove unmapped reads
        
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
        elif 'qseqid' in df.columns: # Sometimes Diamond uses qseqid
             df.rename(columns={'qseqid': 'CDS', 'sseqid': 'Protein'}, inplace=True)
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

def main():
    print("=== Starting Multi-Queue Merger ===")
    
    # 1. Find all queue directories (fila_1, fila_2, etc.)
    queue_pattern = os.path.join(FUNCTIONAL_DIR, "fila_*")
    queue_dirs = glob.glob(queue_pattern)
    
    if not queue_dirs:
        print(f"Error: No queue folders found in {FUNCTIONAL_DIR}")
        exit()

    print(f"Found {len(queue_dirs)} queues. Processing...")
    
    all_samples = []

    # 2. Iterate through each queue
    for queue_path in sorted(queue_dirs):
        queue_name = os.path.basename(queue_path)
        print(f"\n-> Entering {queue_name}...")
        
        idxstats_dir = os.path.join(queue_path, "idxstats")
        diamond_dir = os.path.join(queue_path, "diamond_results_filtrados")
        
        if not os.path.exists(idxstats_dir):
            print(f"   [Skip] idxstats folder missing in {queue_name}")
            continue

        # Get files in this specific queue
        files = [f for f in os.listdir(idxstats_dir) if f.endswith(".idxstats.txt")]
        
        count = 0
        for file in files:
            # Clean filename to get Sample ID
            sample_id = file.replace(".idxstats.txt", "").replace("_aligned_fna", "")
            
            idx_path = os.path.join(idxstats_dir, file)
            # Try matching diamond file (check for _matches.tsv)
            diamond_path = os.path.join(diamond_dir, f"{sample_id}_matches.tsv")
            
            if not os.path.exists(diamond_path):
                 # Fallback: check just .tsv
                 diamond_path = os.path.join(diamond_dir, f"{sample_id}.tsv")

            if os.path.exists(diamond_path):
                df_idx = load_idxstats(idx_path)
                df_diamond = load_diamond(diamond_path)
                
                if df_idx is not None and df_diamond is not None:
                    # Inner join: Keep only annotated genes
                    df_merged = df_diamond.merge(df_idx, on='CDS', how='inner')
                    df_merged['Sample'] = sample_id
                    all_samples.append(df_merged)
                    count += 1
            else:
                # print(f"   [Warning] Diamond file missing for: {sample_id}")
                pass
        
        print(f"   Processed {count} samples in {queue_name}")

    if not all_samples:
        print("Error: No data processed.")
        exit()

    # 3. Concatenate and Save Intermediate File
    print("\nConcatenating all data...")
    final_df = pd.concat(all_samples, ignore_index=True)
    final_df.to_csv(UNIFIED_FILE, sep='\t', index=False)
    print(f"Saved unified table: {UNIFIED_FILE}")

    # 4. Add Group Information
    print("Mapping Groups...")
    
    # Handle .gz extension if necessary
    map_path = SAMPLE_MAP
    if not os.path.exists(map_path) and os.path.exists(map_path + ".gz"):
        map_path += ".gz"

    if os.path.exists(map_path):
        try:
            # Auto-detect separator
            df_map = pd.read_csv(map_path, sep=None, engine='python')
            df_map.columns = df_map.columns.str.strip()
            
            # Smart column detection
            cols = df_map.columns
            col_id = next((c for c in ['run_accession', 'Run', 'Sample', 'Accession'] if c in cols), None)
            col_group = next((c for c in ['Group', 'AMYLOID', 'Condition', 'Disease'] if c in cols), None)

            if col_id and col_group:
                print(f"   Mapping: '{col_id}' -> '{col_group}'")

                # Prepare map
                df_clean_map = df_map[[col_id, col_group]].rename(columns={col_id: 'Sample', col_group: 'Group'})
                df_clean_map['Sample'] = df_clean_map['Sample'].astype(str).str.strip()
                df_clean_map = df_clean_map.drop_duplicates(subset='Sample')

                # Ensure sample types match
                final_df['Sample'] = final_df['Sample'].astype(str).str.strip()

                # Final Merge
                df_final_grouped = final_df.merge(df_clean_map, on='Sample', how='left')
                
                # Fill N/A groups
                df_final_grouped['Group'] = df_final_grouped['Group'].fillna('Unknown')
                
                df_final_grouped.to_csv(FINAL_FILE, sep='\t', index=False)
                print(f"✅ Final table with groups saved: {FINAL_FILE}")
            else:
                print("   [Error] Could not identify Sample/Group columns in map file.")
        except Exception as e:
            print(f"   [Error] Processing sample map: {e}")
    else:
        print("   [Warning] Sample map not found. Skipping group addition.")

if __name__ == "__main__":
    main()