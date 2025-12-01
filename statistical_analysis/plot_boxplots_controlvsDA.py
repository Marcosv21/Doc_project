import pandas as pd
import seaborn as sns
import matplotlib.pyplot as plt
import numpy as np
import os

BASE_DIR = "/home/marcos/PRJEB59406"
FILE_SAMPLE_MAP = f"{BASE_DIR}/sample_map.csv"
OUTPUT_DIR = f"{BASE_DIR}/abundance_results/plots_comparativos"
os.makedirs(OUTPUT_DIR, exist_ok=True)

# Select table (Family names vs Original IDs)
if os.path.exists(f"{BASE_DIR}/abundance_results/tpm_matrix_families.tsv"):
    FILE_TPM = f"{BASE_DIR}/abundance_results/tpm_matrix_families.tsv"
    print("-> Using table with family names.")
else:
    FILE_TPM = f"{BASE_DIR}/abundance_results/tpm_matrix.tsv"
    print("-> Using original table (k141...).")

print("1. Loading data...")
df = pd.read_csv(FILE_TPM, sep="\t", index_col="gene_id")

if not os.path.exists(FILE_SAMPLE_MAP):
    print("\nERROR: 'sample_map.csv' not found!")
    print("Please create the file in the format: ERR_code, Name...")
    exit()

try:
    sample_map = pd.read_csv(FILE_SAMPLE_MAP, header=None, index_col=0)[1].to_dict()
    df = df.rename(columns=sample_map)
    
    print(f"   Columns now: {df.columns.tolist()[:3]} ...")
except Exception as e:
    print(f"   Error reading map: {e}")
    exit()

control = []
sick = []

for col in df.columns:
    c_lower = col.lower()
    if "control" in c_lower or "controle" in c_lower:
        control.append(col)
    elif "atopic" in c_lower or "dermatite" in c_lower or "disease" in c_lower:
        sick.append(col)

print(f"\nControl Group: {len(control)} samples")
print(f"Disease Group: {len(sick)} samples")

if len(control) == 0 or len(sick) == 0:
    print("ERROR: Empty groups. Check if CSV names contain 'Control' or 'Dermatitis'/'Atopic'.")
    exit()

df['mean_ctrl'] = df[control].mean(axis=1)
df['mean_dis'] = df[sick].mean(axis=1)
# Calculate Log2 Fold Change with pseudocount
df['log2fc'] = np.log2((df['mean_dis'] + 0.1) / (df['mean_ctrl'] + 0.1))

# Try to find Sialidase/GH33. If not found, select by highest Fold Change.
termos_interesse = ['GH33', 'sialidase', 'neuraminidase', 'CBM40', 'CBM']
genes_interesse = []

for gene in df.index:
    for termo in termos_interesse:
        if termo.lower() in str(gene).lower():
            genes_interesse.append(gene)

if len(genes_interesse) > 0:
    print(f"\nFound {len(genes_interesse)} genes of interest (Sialidase/GH33)!")
    top_genes = df.loc[genes_interesse].sort_values('log2fc', ascending=False).head(6).index.tolist()
else:
    print("\nNo specific terms found. Selecting top 6 genes by general increase.")
    top_genes = df.sort_values('log2fc', ascending=False).head(6).index.tolist()

# --- PLOT ---
print(f"Plotting: {top_genes}")
cols_to_plot = control + sick
df_plot = df.loc[top_genes, cols_to_plot].reset_index()

df_melted = df_plot.melt(id_vars='gene_id', var_name='Sample', value_name='TPM')

df_melted['Group'] = df_melted['Sample'].apply(lambda x: 'Control' if x in control else 'Dermatitis')

plt.figure(figsize=(10, 8))

sns.boxplot(data=df_melted, x='gene_id', y='TPM', hue='Group', 
            palette={'Control': '#A8DADC', 'Dermatitis': '#E63946'}, 
            showfliers=False) 

sns.stripplot(data=df_melted, x='gene_id', y='TPM', hue='Group', 
              dodge=True, color='black', alpha=0.6, jitter=True)

plt.title("Top differential genes", fontsize=16)
plt.ylabel("TPM Abundance", fontsize=12)
plt.xlabel("Gene ID", fontsize=12)
plt.xticks(rotation=45, ha='right')
plt.tight_layout()

file_out = os.path.join(OUTPUT_DIR, "boxplot_mapped.png")
plt.savefig(file_out, dpi=300)
print(f"\nGraph saved in: {file_out}")