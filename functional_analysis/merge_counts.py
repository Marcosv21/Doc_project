import pandas as pd
import glob
import os

INPUT_DIR = "/home/marcos/PRJEB59406/idxstats"
OUTPUT_DIR = "/home/marcos/PRJEB59406/abundance_results"
os.makedirs(OUTPUT_DIR, exist_ok=True)
archives = glob.glob(os.path.join(INPUT_DIR, "*.idxstats.txt"))

cont = {}
size = {}

for arquivo in archives:
    basename = os.path.basename(arquivo)
    sample_name = basename.replace(".idxstats.txt", "").replace("_aligned_fna", "")
    
    print(f"Lendo: {sample_name}")
    
    try:
        df = pd.read_csv(arquivo, sep="\t", header=None, names=['gene_id', 'length', 'mapped', 'unmapped'])
        
        df = df[df['gene_id'] != '*']
        
        dict_actual_size = df.set_index('gene_id')['length'].to_dict()
        size.update(dict_actual_size)
        
        cont[sample_name] = df.groupby('gene_id')['mapped'].sum()
        
    except Exception as e:
        print(f"ERROR IN {sample_name}: {e}")


df_counts = pd.DataFrame(cont)

df_counts = df_counts.fillna(0).astype(int)

df_lengths = pd.DataFrame.from_dict(size, orient='index', columns=['length'])

commun_genes = df_counts.index.intersection(df_lengths.index)
df_counts = df_counts.loc[commun_genes]
df_lengths = df_lengths.loc[commun_genes]

file_counts = os.path.join(OUTPUT_DIR, "raw_counts_matrix.tsv")
df_counts.to_csv(file_counts, sep="\t", index_label="gene_id")

file_lengths = os.path.join(OUTPUT_DIR, "gene_lengths.tsv")
df_lengths.to_csv(file_lengths, sep="\t", index_label="gene_id")

print(f"Sucess!, genes id total: {len(df_counts)}") 