import pandas as pd
import glob
import os

# --- CONFIGURATION ---
PATH_BINS_PATTERN = "/home/marcos/PRJEB59406/ORGANIZED_RESULTS/taxonomy/fila_*/filtered_bins_high_quality/*.fa"
FILE_ABUNDANCE = "/home/marcos/PRJEB59406/ORGANIZED_RESULTS/functional/unified_abundance_with_groups.tsv"
FILE_MASTER_TABLE = "/home/marcos/PRJEB59406/ORGANIZED_RESULTS/taxonomy/master_table_mag_sialidase.csv" 
OUTPUT_FILE = "/home/marcos/PRJEB59406/ORGANIZED_RESULTS/taxonomy/Final_Table_Taxonomy_Function.tsv"

def main():
    print("=== STARTING FINAL TABLE CREATION ===")
    os.makedirs(os.path.dirname(OUTPUT_FILE), exist_ok=True)

    # 1. LOAD ABUNDANCE
    print(f"\n1. Loading Abundance: {FILE_ABUNDANCE}")
    if not os.path.exists(FILE_ABUNDANCE):
        return print(f"Error: Abundance file not found.")

    try:
        df_abund = pd.read_csv(FILE_ABUNDANCE, sep='\t')
        print(f"   -> Rows loaded: {len(df_abund)}")
    except Exception as e:
        return print(f"Error reading abundance: {e}")

    # Determine ID column and format
    id_col = df_abund.columns[0]
    sample_id = str(df_abund[id_col].iloc[0])
    
    # 2. MAP IDs TO BINS
    if "bin." in sample_id:
        print("   -> BIN format detected. Using direct mapping.")
        df_abund['mag_id_clean'] = df_abund[id_col].astype(str).str.replace('.fa', '', regex=False)
    else:
        print("   -> CONTIG/GENE format detected. Mapping to Bins...")
        
        fasta_files = glob.glob(PATH_BINS_PATTERN)
        if not fasta_files:
            return print(f"Error: No FASTA files found in: {PATH_BINS_PATTERN}")
        
        print(f"   -> Reading headers from {len(fasta_files)} genome files...")
        
        contig_to_bin = {}
        for fasta in fasta_files:
            bin_name = os.path.basename(fasta).replace('.fa', '')
            try:
                with open(fasta, 'r') as f:
                    for line in f:
                        if line.startswith('>'):
                            contig_id = line.split()[0].replace('>', '').strip()
                            contig_to_bin[contig_id] = bin_name
            except Exception: pass

        # Map IDs
        df_abund['mag_id_clean'] = df_abund[id_col].map(contig_to_bin)
        
        # Handle gene suffixes (e.g., _1)
        missing = df_abund['mag_id_clean'].isna()
        if missing.any():
            print("   -> Adjusting gene suffixes...")
            df_abund.loc[missing, 'temp_id'] = df_abund.loc[missing, id_col].apply(
                lambda x: str(x).rsplit('_', 1)[0] if '_' in str(x) else x
            )
            df_abund.loc[missing, 'mag_id_clean'] = df_abund.loc[missing, 'temp_id'].map(contig_to_bin)
            df_abund.drop(columns=['temp_id'], inplace=True)

    # Filter mapped entries
    df_abund_binned = df_abund.dropna(subset=['mag_id_clean'])
    print(f"   -> {len(df_abund_binned)} rows successfully linked to Bins.")

    # 3. MERGE WITH MASTER TABLE
    print(f"\n3. Merging with Master Table: {FILE_MASTER_TABLE}")
    
    if not os.path.exists(FILE_MASTER_TABLE):
        return print(f"Error: Master Table not found.")
        
    df_master = pd.read_csv(FILE_MASTER_TABLE, sep='\t')
    
    # Clean IDs for merging
    master_id_col = df_master.columns[0] 
    df_master[master_id_col] = df_master[master_id_col].astype(str).str.strip()
    
    df_final = pd.merge(df_abund_binned, df_master, left_on='mag_id_clean', right_on=master_id_col, how='left')

    # 4. SAVE
    print("\n4. Saving...")
    
    valid_tax = df_final['Species'].notna().sum() if 'Species' in df_final.columns else 0
    print(f"   -> {valid_tax} rows have taxonomic classification.")
    
    if valid_tax == 0:
        print("Warning: No taxonomy matches found. Check IDs.")

    df_final.to_csv(OUTPUT_FILE, sep='\t', index=False)
    print(f"Success! File saved to:\n{OUTPUT_FILE}")

if __name__ == "__main__":
    main()