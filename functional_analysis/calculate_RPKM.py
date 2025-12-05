import pandas as pd
import os

INPUT_DIR = "/home/marcos/PRJEB59406/abundance_results"
FILE_COUNTS = os.path.join(INPUT_DIR, "raw_counts_matrix.tsv")
FILE_LENGTHS = os.path.join(INPUT_DIR, "gene_lengths.tsv")
FILE_OUTPUT = os.path.join(INPUT_DIR, "rpkm_matrix.tsv")

try:
    df_counts = pd.read_csv(FILE_COUNTS, sep="\t", index_col="gene_id")
    df_lengths = pd.read_csv(FILE_LENGTHS, sep="\t", index_col="gene_id")
    genes_comuns = df_counts.index.intersection(df_lengths.index)
    
    df_counts = df_counts.loc[genes_comuns]
    df_lengths = df_lengths.loc[genes_comuns]
    
    total_reads_per_sample = df_counts.sum(axis=0)
    scaling_factor = total_reads_per_sample / 1_000_000.0
    rpm = df_counts.div(scaling_factor, axis=1)
    lengths_kb = df_lengths['length'] / 1000.0
    
    rpkm = rpm.div(lengths_kb, axis=0)
    
    rpkm = rpkm.fillna(0.0).round(2)
    
    rpkm.to_csv(FILE_OUTPUT, sep="\t", index_label="gene_id")
    
    print(f"\n Save in: {FILE_OUTPUT}")

except Exception as e:
    print(f"Error: {e}")