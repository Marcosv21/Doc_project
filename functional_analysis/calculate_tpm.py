import pandas as pd
import os

INPUT_DIR = "/home/marcos/PRJEB59406/abundance_results"
FILE_COUNTS = os.path.join(INPUT_DIR, "raw_counts_matrix.tsv")
FILE_LENGTHS = os.path.join(INPUT_DIR, "gene_lengths.tsv")
FILE_OUTPUT = os.path.join(INPUT_DIR, "tpm_matrix.tsv")

try:
    df_counts = pd.read_csv(FILE_COUNTS, sep="\t", index_col="gene_id")
    df_lengths = pd.read_csv(FILE_LENGTHS, sep="\t", index_col="gene_id")
    genes_comuns = df_counts.index.intersection(df_lengths.index)
    
    df_counts = df_counts.loc[genes_comuns]
    df_lengths = df_lengths.loc[genes_comuns]
    
    lengths_kb = df_lengths['length'] / 1000.0
    
    rpk = df_counts.div(lengths_kb, axis=0)

    scaling_factor = rpk.sum(axis=0) / 1_000_000.0

    tpm = rpk.div(scaling_factor, axis=1)

    tpm = tpm.round(2)
    
    tpm.to_csv(FILE_OUTPUT, sep="\t", index_label="gene_id")
    print(tpm.head())

except Exception as e:
    print(f"ERROR: {e}")