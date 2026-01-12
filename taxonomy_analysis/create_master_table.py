import pandas as pd
import os
import glob
# Define directories
GTDB_DIR = "/home/marcos/PRJEB59406/taxonomy_gtdb"
DIAMOND_DIR = "/home/marcos/PRJEB59406/mag_annotation/diamond_matches"
OUTPUT_FILE = "/home/marcos/PRJEB59406/tabela_mestra_mag_sialidase.xlsx"
# Load GTDB-Tk taxonomy summaries
def main():
    gtdb_files = glob.glob(os.path.join(GTDB_DIR, "gtdbtk.*.summary.tsv")) # Adjust pattern as needed to match your files 
    # Read and concatenate all GTDB-Tk summary files
    dfs_gtdb = [] # List to hold individual dataframes 
    for f in gtdb_files: # Iterate over each GTDB-Tk summary file 
        try: # Try to read the file
            df = pd.read_csv(f, sep="\t", usecols=['user_genome', 'classification'])
            dfs_gtdb.append(df)
        except Exception as e:
            print(f"   Error lecture {f}: {e}")
            # Skip files that cannot be read 
    if not dfs_gtdb:
        print(" anything not found summary.tsv with GTDB-Tk")
        return
    df_tax = pd.concat(dfs_gtdb)
    
    df_tax['mag_id'] = df_tax['user_genome'].astype(str).str.replace(r'\.(fa|fasta|fna)$', '', regex=True)
    
    print(f"   Taxonomy loaded for {len(df_tax)} MAGs.")

    diamond_files = glob.glob(os.path.join(DIAMOND_DIR, "*_sialidase_hits.tsv"))
    # Process Diamond sialidase hit files 
    mag_sialidase_data = []
# Iterate over each Diamond output file 
    for f in diamond_files:
        filename = os.path.basename(f)
        mag_id = filename.replace("_sialidase_hits.tsv", "")
        # Check if the file is not empty 
        if os.path.getsize(f) > 0:
            try: # Try to read the Diamond output file 
                df_hits = pd.read_csv(f, sep="\t", header=None)
                num_hits = len(df_hits)
                # Get the best hit (first row, second column) 
                best_hit = df_hits.iloc[0, 1] 
                # Append data to the list 
                mag_sialidase_data.append({
                    'mag_id': mag_id,
                    'has_sialidase': 'YES',        
                    'gene_copy_number': num_hits,  
                    'best_db_hit': best_hit        
                }) # End of append 
            except pd.errors.EmptyDataError:
               mag_sialidase_data.append({'mag_id': mag_id, 'has_sialidase': 'NO', 'gene_copy_number': 0, 'best_db_hit': '-'})
        else:
            mag_sialidase_data.append({'mag_id': mag_id, 'has_sialidase': 'NO', 'gene_copy_number': 0, 'best_db_hit': '-'})

    df_func = pd.DataFrame(mag_sialidase_data)
   
    print("\n3. Merging tables...")
    # Merge taxonomy and functional data 
    df_final = pd.merge(df_tax, df_func, on='mag_id', how='left')
    #  Fill NaN values for MAGs without sialidase data 
    df_final['has_sialidase'] = df_final['has_sialidase'].fillna('No Data')
    df_final['gene_copy_number'] = df_final['gene_copy_number'].fillna(0)
    # Fill best_db_hit with '-' for MAGs without sialidase data
    df_final = df_final[['mag_id', 'classification', 'has_sialidase', 'gene_copy_number', 'best_db_hit']]
    # Save final table to Excel 
    print(f"\n4. Saving to {OUTPUT_FILE}...")
    df_final.to_excel(OUTPUT_FILE, index=False)
    print("Done.")
if __name__ == "__main__":
    main()