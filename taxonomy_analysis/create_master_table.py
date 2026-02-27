import pandas as pd
import os
import glob
import re

# Configuration
GTDB_DIR = "/home/marcos/PRJEB59406/ORGANIZED_RESULTS/taxonomy/fila_*/taxonomy_gtdb"
DIAMOND_DIR = "/home/marcos/PRJEB59406/ORGANIZED_RESULTS/taxonomy/fila_*/mag_annotation/diamond_matches"
OUTPUT_FILE = "/home/marcos/PRJEB59406/ORGANIZED_RESULTS/taxonomy/master_table_mag_sialidase_gtdb.csv"

def parse_taxonomy(tax_string):
    """Splits the GTDB string into clean Phylum, Genus, and Species."""
    if pd.isna(tax_string):
        return pd.Series(['Unknown', 'Unknown', 'Unknown'])
    
    # Extract levels using simple string splitting
    parts = tax_string.split(';')
    p = next((x.split('__')[1] for x in parts if 'p__' in x), 'Unknown')
    g = next((x.split('__')[1] for x in parts if 'g__' in x), 'Unknown')
    s = next((x.split('__')[1] for x in parts if 's__' in x), 'Unknown')
    return pd.Series([p, g, s])

def main():
    # 1. Load Taxonomy Data
    tax_files = glob.glob(os.path.join(GTDB_DIR, "gtdbtk.*.summary.tsv"))
    if not tax_files: return print("No GTDB files found.")
    
    df_tax = pd.concat([pd.read_csv(f, sep="\t", usecols=['user_genome', 'classification']) for f in tax_files])
    
    # Standardize ID to 'bin.X'
    df_tax['mag_id'] = df_tax['user_genome'].str.extract(r'(bin\.\d+)', expand=False)
    
    # Split taxonomy into columns
    df_tax[['Phylum', 'Genus', 'Species']] = df_tax['classification'].apply(parse_taxonomy)
    print(f"Taxonomy loaded: {len(df_tax)} MAGs")

    # 2. Load Diamond (Functional) Data
    diamond_files = glob.glob(os.path.join(DIAMOND_DIR, "*_hits_sial.tsv"))
    func_results = []
    
    for f in diamond_files:
        # Extract 'bin.X' from filename
        mid_match = re.search(r'(bin\.\d+)', os.path.basename(f))
        mid = mid_match.group(1) if mid_match else os.path.basename(f)
        
        if os.path.getsize(f) > 0:
            hits = pd.read_csv(f, sep="\t", header=None)
            func_results.append({
                'mag_id': mid, 
                'has_nanH': 'YES' if any(hits.iloc[:, 1].str.contains('nanH', case=False, na=False)) else 'NO',
                'has_nanE': 'YES' if any(hits.iloc[:, 1].str.contains('nanE', case=False, na=False)) else 'NO',
                'has_nanK': 'YES' if any(hits.iloc[:, 1].str.contains('nanK', case=False, na=False)) else 'NO',
                'has_nanA': 'YES' if any(hits.iloc[:, 1].str.contains('nanA', case=False, na=False)) else 'NO',
                'has_nanT': 'YES' if any(hits.iloc[:, 1].str.contains('nanT', case=False, na=False)) else 'NO',
                'gene_count': len(hits), 
                'best_hit': hits.iloc[0, 1]
            })
        else:
            func_results.append({'mag_id': mid, 'has_nanH': 'NO', 'has_nanE': 'NO', 'has_nanK': 'NO', 'has_nanA': 'NO', 'has_nanT': 'NO', 'gene_count': 0, 'best_hit': '-'})

    df_func = pd.DataFrame(func_results).drop_duplicates(subset='mag_id')

    # 3. Merge and Clean
    df_final = pd.merge(df_tax, df_func, on='mag_id', how='left')
    
    # Fill missing values for MAGs with no Diamond hits
    df_final['has_nanH'] = df_final['has_nanH'].fillna('NO')
    df_final['has_nanE'] = df_final['has_nanE'].fillna('NO')
    df_final['has_nanK'] = df_final['has_nanK'].fillna('NO')
    df_final['has_nanA'] = df_final['has_nanA'].fillna('NO')
    df_final['has_nanT'] = df_final['has_nanT'].fillna('NO')
    df_final['gene_count'] = df_final['gene_count'].fillna(0)
    df_final['best_hit'] = df_final['best_hit'].fillna('-')

    # Select and reorder columns
    final_cols = ['mag_id', 'Phylum', 'Genus', 'Species', 'has_nanH', 'has_nanE', 'has_nanK', 'has_nanA', 'has_nanT', 'gene_count', 'best_hit']
    df_final = df_final[final_cols]

    # 4. Save
    df_final.to_csv(OUTPUT_FILE, index=False, sep="\t")
    print(f"Success! Master table saved to: {OUTPUT_FILE}")
    print(f"Found {len(df_final[df_final['has_nanH']=='YES'])} nanH-positive MAGs.")
    print(f"Found {len(df_final[df_final['has_nanE']=='YES'])} nanE-positive MAGs.")
    print(f"Found {len(df_final[df_final['has_nanK']=='YES'])} nanK-positive MAGs.")
    print(f"Found {len(df_final[df_final['has_nanA']=='YES'])} nanA-positive MAGs.")
    print(f"Found {len(df_final[df_final['has_nanT']=='YES'])} nanT-positive MAGs.")
    

if __name__ == "__main__":
    main()