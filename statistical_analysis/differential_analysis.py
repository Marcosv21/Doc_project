import pandas as pd
import numpy as np
from scipy import stats
from statsmodels.stats.multitest import multipletests
import matplotlib.pyplot as plt
import seaborn as sns
import os

BASE_DIR = "/home/marcos/PRJEB59406"
FILE_SAMPLE_MAP = f"{BASE_DIR}/sample_map.csv"

if os.path.exists(f"{BASE_DIR}/abundance_results/rpkm_matrix_families.tsv"):
    FILE_TPM = f"{BASE_DIR}/abundance_results/rpkm_matrix_families.tsv"
    print("-> Using renamed table (families)")
else:
    FILE_TPM = f"{BASE_DIR}/abundance_results/rpkm_matrix.tsv"
    print("-> Using original table")

OUTPUT_DIR = f"{BASE_DIR}/abundance_results/differential_analysis"
os.makedirs(OUTPUT_DIR, exist_ok=True)

print("Loading data...")
df_tpm = pd.read_csv(FILE_TPM, sep="\t", index_col="gene_id")

if os.path.exists(FILE_SAMPLE_MAP):
    print("   Loading sample map...")
    try:
        sample_map = pd.read_csv(FILE_SAMPLE_MAP, header=None, index_col=0)[1].to_dict()
    except Exception as e:
        sample_map = {}
else:
    sample_map = {}

groups = {}
print("Detecting groups...")

for col_name in df_tpm.columns:
    if col_name in sample_map:
        name_to_check = sample_map[col_name].lower() # Use translated name
    else:
        name_to_check = col_name.lower() # Use original name

    g_name = None
    if "control" in name_to_check or "controle" in name_to_check:
        g_name = "Control"
    elif "atopic" in name_to_check or "dermatite" in name_to_check or "disease" in name_to_check:
        g_name = "Dermatitis"
    
    if g_name:
        if g_name not in groups: groups[g_name] = []
        groups[g_name].append(col_name) # Store the ORIGINAL column name
    else:
        print(f"   WARNING: Sample '{col_name}' (Translated: '{name_to_check}') ignored.")

group_names = list(groups.keys())

if len(group_names) != 2:
    exit()

GROUP_A = "Control"      # Reference
GROUP_B = "Dermatitis"   # Disease

if GROUP_A not in groups: GROUP_A = group_names[0]
if GROUP_B not in groups: GROUP_B = group_names[1]

print(f"COMPARING: {GROUP_B} ({len(groups[GROUP_B])}) vs {GROUP_A} ({len(groups[GROUP_A])})")

df_tpm = df_tpm[groups[GROUP_A] + groups[GROUP_B]]

results = []

for gene in df_tpm.index:
    vals_a = df_tpm.loc[gene, groups[GROUP_A]]
    vals_b = df_tpm.loc[gene, groups[GROUP_B]]
    
    mean_a = np.mean(vals_a)
    mean_b = np.mean(vals_b)
    
    if mean_a == 0 and mean_b == 0: continue

    # Log2FC with pseudocount
    log2fc = np.log2((mean_b + 0.01) / (mean_a + 0.01))
    
    try:
        stat, pval = stats.mannwhitneyu(vals_a, vals_b, alternative='two-sided')
    except:
        pval = 1.0

    results.append({
        'gene_id': gene,
        f'mean_{GROUP_A}': mean_a,
        f'mean_{GROUP_B}': mean_b,
        'log2FC': log2fc,
        'p_value': pval
    })

df_res = pd.DataFrame(results).set_index('gene_id')
df_res['p_adj'] = multipletests(df_res['p_value'], method='fdr_bh')[1]

def classify(row):
    if row['p_adj'] < 0.05:
        if row['log2FC'] > 1: return f'Up in {GROUP_B}'
        if row['log2FC'] < -1: return f'Down in {GROUP_B}'
    return 'NS'

df_res['Status'] = df_res.apply(classify, axis=1)

file_table = os.path.join(OUTPUT_DIR, "differential_genes.tsv")
df_res.sort_values('p_adj').to_csv(file_table, sep="\t")
print(f"Table saved: {file_table}")

print("Generating Volcano Plot...")
plt.figure(figsize=(10, 8))

sns.scatterplot(data=df_res, x='log2FC', y=-np.log10(df_res['p_adj'] + 1e-300), 
                hue='Status', 
                palette={f'Up in {GROUP_B}': '#2ca25f', f'Down in {GROUP_B}': '#e34a33', 'NS': 'lightgrey'},
                alpha=0.8, s=30, edgecolor=None)

plt.axvline(x=1, color='black', linestyle='--', lw=0.8, alpha=0.5)
plt.axvline(x=-1, color='black', linestyle='--', lw=0.8, alpha=0.5)
plt.axhline(y=-np.log10(0.05), color='black', linestyle='--', lw=0.8, alpha=0.5)

plt.title(f"Volcano Plot: {GROUP_B} vs {GROUP_A}", fontsize=15)
plt.xlabel("Log2 Fold Change", fontsize=12)
plt.ylabel("-Log10 FDR", fontsize=12)

top_genes = df_res[df_res['Status'] != 'NS'].sort_values('p_adj').head(10)
texts = []
for gene in top_genes.index:
    texts.append(plt.text(top_genes.loc[gene, 'log2FC'], 
                          -np.log10(top_genes.loc[gene, 'p_adj'] + 1e-300), 
                          gene, fontsize=9, weight='bold'))

try:
    from adjustText import adjust_text
    adjust_text(texts, arrowprops=dict(arrowstyle='-', color='black', lw=0.5))
except ImportError:
    print("   Warning: adjustText library not installed.")

file_plot = os.path.join(OUTPUT_DIR, "volcano_plot_final.png")
plt.savefig(file_plot, dpi=300, bbox_inches='tight')
print(f"Graph saved at: {file_plot}")