import pandas as pd
import seaborn as sns
import matplotlib.pyplot as plt
import numpy as np
import os

BASE_DIR = "/home/marcos/PRJEB59406"
FILE_TPM = f"{BASE_DIR}/abundance_results/tpm_matrix.tsv" 
OUTPUT_DIR = f"{BASE_DIR}/abundance_results"
FILE_SAMPLE_MAP = f"{BASE_DIR}/sample_map.csv"

df = pd.read_csv(FILE_TPM, sep="\t", index_col="gene_id")

gene_example = df.index[0]

if "_" not in str(gene_example) and "k141" in str(gene_example):
    print("   Warning.")

if os.path.exists(FILE_SAMPLE_MAP):
    try:
        sample_map = pd.read_csv(FILE_SAMPLE_MAP, header=None, index_col=0)[1].to_dict()
        df = df.rename(columns=sample_map)
    except Exception as e:
        print(f"ERROR sample_map: {e}")
else:
    print("\n2. Sample map not found. Proceeding with original column names.\n")

file_out = os.path.join(OUTPUT_DIR, "tpm_matrix_final.tsv")
df.to_csv(file_out, sep="\t")

try:
    df['mean'] = df.mean(axis=1)
    df_top = df.sort_values(by='mean', ascending=False).head(50).drop(columns=['mean'])

    df_log = np.log1p(df_top)

    plt.figure(figsize=(14, 16))
    
    g = sns.clustermap(df_log, 
                       method='ward', 
                       cmap='viridis', 
                       metric='euclidean',
                       figsize=(14, 16), 
                       dendrogram_ratio=(.1, .2), 
                       cbar_pos=(0, .2, .03, .4))

    g.ax_heatmap.set_title(f"Top {50} Genes (TPM abundance)", pad=100)
    
    plt.setp(g.ax_heatmap.get_xticklabels(), rotation=45, ha="right", fontsize=10)
    plt.setp(g.ax_heatmap.get_yticklabels(), rotation=0, fontsize=8) 

    img_out = os.path.join(OUTPUT_DIR, "heatmap_final.png")
    plt.savefig(img_out, dpi=300, bbox_inches='tight')
    print(f"   Finish! You image in {img_out}")

except Exception as e:
    print(f"   ERROR: {e}")