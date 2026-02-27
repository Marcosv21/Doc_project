import os
import pandas as pd
import glob
import numpy as np

BASE_PATH = "/home/marcos/PRJEB59406/ORGANIZED_RESULTS"
FUNCTIONAL_DIR = os.path.join(BASE_PATH, "functional")

OUTPUT_COUNTS = os.path.join(FUNCTIONAL_DIR, "matrix_counts.tsv") #DESeq2
OUTPUT_TPM = os.path.join(FUNCTIONAL_DIR, "matrix_tpm.tsv") #visualization
OUTPUT_LONG = os.path.join(FUNCTIONAL_DIR, "long_format_table.tsv") #CLR -> SPIEC-EASI


# =========================
# Functions
# =========================

def load_idxstats(path):
    df = pd.read_csv(path, sep='\t', header=None,
                     names=['CDS', 'Length', 'Mapped', 'Unmapped'])
    df = df[df['CDS'] != '*'].copy()
    return df[['CDS', 'Length', 'Mapped']]


def load_diamond(path):
    df = pd.read_csv(path, sep='\t')

    if 'seqid' in df.columns:
        df.rename(columns={'seqid': 'CDS', 'sseqid': 'Protein'}, inplace=True)
    elif 'qseqid' in df.columns:
        df.rename(columns={'qseqid': 'CDS', 'sseqid': 'Protein'}, inplace=True)
    else:
        df = pd.read_csv(path, sep='\t', header=None)
        df = df.iloc[:, [0, 1]]
        df.columns = ['CDS', 'Protein']

    return df[['CDS', 'Protein']]


def calculate_tpm(df):
    # Calculate the ratio (Mapped / Length) for each protein/gene
    ratio = df['Mapped'] / df['Length']
    
    # Sum all ratios in the sample
    sum_ratios = ratio.sum()
    
    # Apply the direct formula if there are counts, preventing division by zero
    if sum_ratios > 0:
        df['TPM'] = 1e6 * (ratio / sum_ratios)
    else:
        df['TPM'] = 0.0
        
    return df


# =========================
# Processing
# =========================

all_long = []

queue_dirs = glob.glob(os.path.join(FUNCTIONAL_DIR, "fila_*"))

for queue_path in sorted(queue_dirs):

    idxstats_dir = os.path.join(queue_path, "idxstats")
    diamond_dir = os.path.join(queue_path, "diamond_results_filtrados")

    files = [f for f in os.listdir(idxstats_dir) if f.endswith(".idxstats.txt")]

    for file in files:

        sample_id = file.replace(".idxstats.txt", "").replace("_aligned_fna", "")

        idx_path = os.path.join(idxstats_dir, file)
        diamond_path = os.path.join(diamond_dir, f"{sample_id}_matches.tsv")

        if not os.path.exists(diamond_path):
            continue

        df_idx = load_idxstats(idx_path)
        df_diamond = load_diamond(diamond_path)

        df_merged = df_diamond.merge(df_idx, on='CDS', how='inner')

        df_merged = calculate_tpm(df_merged)

        df_merged['Sample'] = sample_id

        # Agruped by Sample and Protein, summing Mapped and TPM
        df_grouped = df_merged.groupby(['Sample', 'Protein']).agg({
            'Mapped': 'sum',
            'TPM': 'sum'
        }).reset_index()

        all_long.append(df_grouped)


# =========================
# Concatenate all long format dataframes
# =========================

final_long = pd.concat(all_long, ignore_index=True)

final_long.to_csv(OUTPUT_LONG, sep='\t', index=False)

# =========================
# Counts Matrix
# =========================

matrix_counts = final_long.pivot_table(
    index='Protein',
    columns='Sample',
    values='Mapped',
    fill_value=0
)

matrix_counts.to_csv(OUTPUT_COUNTS, sep='\t')

# =========================
# TPM Matrix
# =========================

matrix_tpm = final_long.pivot_table(
    index='Protein',
    columns='Sample',
    values='TPM',
    fill_value=0
)

matrix_tpm.to_csv(OUTPUT_TPM, sep='\t')

print(" Matrizes geradas:")
print(" - Counts:", OUTPUT_COUNTS)
print(" - TPM:", OUTPUT_TPM)
print(" - Long format:", OUTPUT_LONG)