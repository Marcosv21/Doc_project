import pandas as pd 
import os
# Define input and output file paths
INPUT_DIR = "/home/marcos/PRJEB59406/abundance_results"
FILE_COUNTS = os.path.join(INPUT_DIR, "raw_counts_matrix.tsv")
FILE_LENGTHS = os.path.join(INPUT_DIR, "gene_lengths.tsv")
FILE_OUTPUT = os.path.join(INPUT_DIR, "rpkm_matrix.tsv")

# Read input files and calculate RPKM values 
try:
    df_counts = pd.read_csv(FILE_COUNTS, sep="\t", index_col="gene_id")
    df_lengths = pd.read_csv(FILE_LENGTHS, sep="\t", index_col="gene_id")
    genes_comuns = df_counts.index.intersection(df_lengths.index)
    # Filtrar ambos DataFrames para incluir solo genes comunes
    df_counts = df_counts.loc[genes_comuns]
    df_lengths = df_lengths.loc[genes_comuns]
    # Calcular RPKM values 
    total_reads_per_sample = df_counts.sum(axis=0) # Somar todas as contagens por amostra
    scaling_factor = total_reads_per_sample / 1_000_000.0 # Calcular fator de escala em milhões de leituras
    rpm = df_counts.div(scaling_factor, axis=1) # Calcular RPKM
    lengths_kb = df_lengths['length'] / 1000.0 # Converter comprimentos de genes para kb
    
    rpkm = rpm.div(lengths_kb, axis=0) # Dividir RPM pelo comprimento do gene em kb
    
    rpkm = rpkm.fillna(0.0).round(2) # Substituir NaN por 0.0 e arredondar para 2 casas decimais
    
    rpkm.to_csv(FILE_OUTPUT, sep="\t", index_label="gene_id") # Salvar matriz RPKM em arquivo TSV
    
    print(f"\n Save in: {FILE_OUTPUT}")

except Exception as e:
    print(f"Error: {e}")