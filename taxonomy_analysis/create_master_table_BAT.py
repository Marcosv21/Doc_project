import pandas as pd
import glob
import os

# --- CONFIGURATION ---
BAT_PATTERN = "/home/marcos/PRJEB59406/ORGANIZED_RESULTS/taxonomy/fila_*/BAT_classification/*_NAMES.*"
DIAMOND_PATTERN = "/home/marcos/PRJEB59406/ORGANIZED_RESULTS/taxonomy/fila_*/mag_annotation/diamond_matches/*_hits_sial.tsv"
OUTPUT_FILE = "/home/marcos/PRJEB59406/ORGANIZED_RESULTS/taxonomy/master_table_mag_sialidase.csv"

def clean_taxonomy(val):
    """Removes confidence scores and handles 'no support' labels."""
    val = str(val)
    if 'no support' in val:
        return 'Unknown'
    return val.split(':')[0].strip()

def main():
    print("--- Generating Master Table ---")

    # 1. LOAD TAXONOMY (BAT)
    bat_files = glob.glob(BAT_PATTERN)
    if not bat_files:
        return print(f"Error: No files found matching {BAT_PATTERN}")
    
    print(f"-> Processing {len(bat_files)} taxonomy files...")
    
    tax_dfs = []
    for f in bat_files:
        try:
            df = pd.read_csv(f, sep='\t')
            
            # Standardize ID column
            if '# bin' in df.columns:
                df.rename(columns={'# bin': 'mag_id'}, inplace=True)
            
            # Select relevant columns if they exist
            target_cols = ['mag_id', 'phylum', 'genus', 'species']
            existing_cols = [c for c in target_cols if c in df.columns]
            
            tax_dfs.append(df[existing_cols])
        except Exception:
            pass

    if not tax_dfs:
        return print("No valid taxonomy data extracted.")

    df_tax = pd.concat(tax_dfs, ignore_index=True)
    
    # Clean IDs and Taxonomy names
    df_tax['clean_id'] = df_tax['mag_id'].astype(str).str.replace('.fa', '', regex=False)
    
    for col in ['phylum', 'genus', 'species']:
        if col in df_tax.columns:
            df_tax[col] = df_tax[col].apply(clean_taxonomy)

    print(f"   Taxonomy loaded: {len(df_tax)} MAGs")

    # 2. LOAD FUNCTION (DIAMOND)
    diamond_files = glob.glob(DIAMOND_PATTERN)
    print(f"-> Processing {len(diamond_files)} function files...")

    func_data = []
    for f in diamond_files:
        mag_id = os.path.basename(f).replace('_hits_sial.tsv', '')
        
        # Check if file has content (hits)
        if os.path.getsize(f) > 0:
            try:
                hits = pd.read_csv(f, sep="\t", header=None)
                func_data.append({
                    'clean_id': mag_id, 
                    'has_sialidase': 'YES', 
                    'gene_count': len(hits), 
                    'best_hit': hits.iloc[0, 1]
                })
            except: pass
        else:
            func_data.append({
                'clean_id': mag_id, 
                'has_sialidase': 'NO', 
                'gene_count': 0, 
                'best_hit': '-'
            })

    df_func = pd.DataFrame(func_data)

    # 3. MERGE AND SAVE
    print("-> Merging data...")
    
    df_final = pd.merge(df_tax, df_func, on='clean_id', how='left')
    
    # Fill missing functional data
    defaults = {'has_sialidase': 'NO', 'gene_count': 0, 'best_hit': '-'}
    df_final.fillna(defaults, inplace=True)
    
    # Select and rename columns
    final_cols = ['clean_id', 'phylum', 'genus', 'species', 'has_sialidase', 'gene_count', 'best_hit']
    final_cols = [c for c in final_cols if c in df_final.columns]
    
    df_final = df_final[final_cols]
    df_final.columns = [c.replace('_', ' ').title() for c in df_final.columns]
    
    df_final.to_csv(OUTPUT_FILE, index=False, sep="\t")
    
    print("-" * 30)
    print(f"Success! File saved to: {OUTPUT_FILE}")
    print(f"Total MAGs: {len(df_final)}")
    
    if 'Has Sialidase' in df_final.columns:
        count = len(df_final[df_final['Has Sialidase'] == 'YES'])
        print(f"MAGs with Sialidase: {count}")

if __name__ == "__main__":
    main()