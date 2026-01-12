import pandas as pd 
import os
# Define input and output file paths
INPUT_DIR = "/home/marcos/PRJEB59406/abundance_results"
FILE_COUNTS = os.path.join(INPUT_DIR, "raw_counts_matrix.tsv")
FILE_LENGTHS = os.path.join(INPUT_DIR, "gene_lengths.tsv")
FILE_OUTPUT = os.path.join(INPUT_DIR, "rpkm_matrix.tsv")

# Read input files and calculate RPKM values 
try:
    df_counts = pd.read_csv(FILE_COUNTS, sep="\t", index_col="gene_id") # Read raw counts matrix
    df_lengths = pd.read_csv(FILE_LENGTHS, sep="\t", index_col="gene_id") # Read gene lengths
    genes_comuns = df_counts.index.intersection(df_lengths.index)
    # Filter between Dataframes to keep only common genes
    df_counts = df_counts.loc[genes_comuns] # Filter counts matrix
    df_lengths = df_lengths.loc[genes_comuns] # Filter lengths matrix
    # RPKM values 
    total_reads_per_sample = df_counts.sum(axis=0) # Calculate total reads per sample
    scaling_factor = total_reads_per_sample / 1_000_000.0 # Calculate scaling factor for RPM
    rpm = df_counts.div(scaling_factor, axis=1) # Calculate RPM values
    lengths_kb = df_lengths['length'] / 1000.0 # Converting gene lengths to kilobases
    
    rpkm = rpm.div(lengths_kb, axis=0) # Calculate RPKM values
    
    rpkm = rpkm.fillna(0.0).round(2) # Substituition of NaN values with 0.0 and rounding to 2 decimal places
    
    rpkm.to_csv(FILE_OUTPUT, sep="\t", index_label="gene_id") # Save RPKM matrix to output file
    
    print(f"\n Save in: {FILE_OUTPUT}")
# Error handling
except Exception as e:
    print(f"Error: {e}")