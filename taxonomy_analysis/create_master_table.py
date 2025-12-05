import pandas as pd
import os
import glob

GTDB_DIR = "/home/marcos/PRJEB59406/taxonomy_gtdb"
DIAMOND_DIR = "/home/marcos/PRJEB59406/mag_annotation/diamond_matches"
OUTPUT_FILE = "/home/marcos/PRJEB59406/tabela_mestra_mag_sialidase.xlsx"

def main():
    gtdb_files = glob.glob(os.path.join(GTDB_DIR, "gtdbtk.*.summary.tsv"))
    
    dfs_gtdb = []
    for f in gtdb_files:
        try:
            df = pd.read_csv(f, sep="\t", usecols=['user_genome', 'classification'])
            dfs_gtdb.append(df)
        except Exception as e:
            print(f"   Error lecture {f}: {e}")
            
    if not dfs_gtdb:
        print(" anything not found summary.tsv with GTDB-Tk")
        return
    df_tax = pd.concat(dfs_gtdb)
    
    df_tax['mag_id'] = df_tax['user_genome'].astype(str).str.replace(r'\.(fa|fasta|fna)$', '', regex=True)
    
    print(f"   Taxonomy loaded for {len(df_tax)} MAGs.")

    diamond_files = glob.glob(os.path.join(DIAMOND_DIR, "*_sialidase_hits.tsv"))
    
    mag_sialidase_data = []

    for f in diamond_files:
        filename = os.path.basename(f)
        mag_id = filename.replace("_sialidase_hits.tsv", "")
        
        if os.path.getsize(f) > 0:
            try:
                df_hits = pd.read_csv(f, sep="\t", header=None)
                num_hits = len(df_hits)
                
                best_hit = df_hits.iloc[0, 1] 
                
                mag_sialidase_data.append({
                    'mag_id': mag_id,
                    'has_sialidase': 'YES',        
                    'gene_copy_number': num_hits,  
                    'best_db_hit': best_hit        
                })
            except pd.errors.EmptyDataError:
               mag_sialidase_data.append({'mag_id': mag_id, 'has_sialidase': 'NO', 'gene_copy_number': 0, 'best_db_hit': '-'})
        else:
            mag_sialidase_data.append({'mag_id': mag_id, 'has_sialidase': 'NO', 'gene_copy_number': 0, 'best_db_hit': '-'})

    df_func = pd.DataFrame(mag_sialidase_data)
   
    print("\n3. Merging tables...")
    
    df_final = pd.merge(df_tax, df_func, on='mag_id', how='left')
    
    df_final['has_sialidase'] = df_final['has_sialidase'].fillna('No Data')
    df_final['gene_copy_number'] = df_final['gene_copy_number'].fillna(0)
    
    df_final = df_final[['mag_id', 'classification', 'has_sialidase', 'gene_copy_number', 'best_db_hit']]
    
    print(f"\n4. Saving to {OUTPUT_FILE}...")
    df_final.to_excel(OUTPUT_FILE, index=False)
    print("Done.")
if __name__ == "__main__":
    main()