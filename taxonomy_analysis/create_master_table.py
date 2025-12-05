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
    
    print(f"   Taxonomia carregada para {len(df_tax)} MAGs.")

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
                    'tem_sialidase': 'SIM',
                    'num_copias_gene': num_hits,
                    'melhor_hit_db': best_hit
                })
            except pd.errors.EmptyDataError:
               mag_sialidase_data.append({'mag_id': mag_id, 'tem_sialidase': 'NÃO', 'num_copias_gene': 0, 'melhor_hit_db': '-'})
        else:
            mag_sialidase_data.append({'mag_id': mag_id, 'tem_sialidase': 'NÃO', 'num_copias_gene': 0, 'melhor_hit_db': '-'})

    df_func = pd.DataFrame(mag_sialidase_data)
   
    print("\n3. Cruzando as tabelas...")
    
    df_final = pd.merge(df_tax, df_func, on='mag_id', how='left')
    
    df_final['tem_sialidase'] = df_final['tem_sialidase'].fillna('Sem Dados')
    df_final['num_copias_gene'] = df_final['num_copias_gene'].fillna(0)
    
    df_final = df_final[['mag_id', 'classification', 'tem_sialidase', 'num_copias_gene', 'melhor_hit_db']]
    
    print(f"\n4. Salvando em {OUTPUT_FILE}...")
    df_final.to_excel(OUTPUT_FILE, index=False)
    print("✅ Sucesso! Tabela criada.")

if __name__ == "__main__":
    main()