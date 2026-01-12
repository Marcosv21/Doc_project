import pandas as pd
import seaborn as sns
import matplotlib.pyplot as plt
import numpy as np
import os
import glob 

# Set paths
BASE_DIR = "/temporario2/17404478/PRJEB59406"
FILE_TPM = f"{BASE_DIR}/abundance_results/rpkm_matrix.tsv"
FILE_SAMPLE_MAP = f"{BASE_DIR}/sample_map.csv"
OUTPUT_DIR = f"{BASE_DIR}/abundance_results"
FILE_ANNOTATION = f"{BASE_DIR}/resultado_anotacao.tsv"
MATCHES_PATTERN = f"{BASE_DIR}/filas_processamento/fila_*/diamond_results_filtrados/*_matches.tsv"

os.makedirs(OUTPUT_DIR, exist_ok=True)

# LOAD DATA & GROUP BY SAMPLE
print("1. Loading RPKM matrix and Sample Map...")
try:
    # Load Matrix
    df = pd.read_csv(FILE_TPM, sep="\t", index_col="gene_id")
    
    # Load Sample Map
    if os.path.exists(FILE_SAMPLE_MAP):
        sample_map = pd.read_csv(FILE_SAMPLE_MAP, sep=None, engine='python')
        sample_map.columns = sample_map.columns.str.strip()
        
        # Create mapping dictionary: { 'ERR123': 'Control' }
        col_id = sample_map.columns[0]
        col_group = sample_map.columns[2]
        map_dict = dict(zip(sample_map[col_id], sample_map[col_group]))
        
        # Filter and Group
        common_samples = df.columns.intersection(map_dict.keys())
        df = df[common_samples]
        df = df.groupby(map_dict, axis=1).mean()
        
        # Save grouped matrix
        df.to_csv(os.path.join(OUTPUT_DIR, "rpkm_matrix_grouped_mean.tsv"), sep="\t")
        print(f"   Grouped by {len(df.columns)} groups: {list(df.columns)}")
    else:
        print("   Warning: sample_map.csv not found. Using raw samples.")

except Exception as e:
    print(f"Error loading data: {e}")
    exit()

# --- 3. RENAMING STEP 1: Matches (k141 -> nanH) ---
print("2. Renaming IDs using match files...")
match_files = glob.glob(MATCHES_PATTERN)
rename_dict = {}

for f in match_files:
    try:
        # Load match file (ignoring headers)
        temp_df = pd.read_csv(f, sep="\t", header=None, dtype=str)
        if 'seqid' in str(temp_df.iloc[0,0]): temp_df = temp_df.iloc[1:]
        
        # Update dictionary
        rename_dict.update(dict(zip(temp_df[0].str.strip(), temp_df[1].str.strip())))
    except:
        pass

# Apply renaming (handling _1 suffix)
new_indices = []
for gene in df.index:
    gene_str = str(gene).strip()
    base_gene = gene_str.rsplit('_', 1)[0] if '_' in gene_str else gene_str
    
    if gene_str in rename_dict:
        new_indices.append(rename_dict[gene_str])
    elif base_gene in rename_dict:
        new_indices.append(rename_dict[base_gene])
    else:
        new_indices.append(gene_str)

df.index = new_indices
print(f"   Step 1 complete.")

# Annotation (nanH -> Gene Name)
print("3. Final renaming using annotation...")
if os.path.exists(FILE_ANNOTATION):
    annot_df = pd.read_csv(FILE_ANNOTATION, sep="\t", header=None, dtype=str)
    
    # Create dictionary: { 'nanH_ID': 'GeneName' }
    final_dict = {}
    for _, row in annot_df.iterrows():
        short_id = str(row[0]).strip()
        full_name = str(row[1]).strip()
        clean_name = full_name.split('|')[-1] if '|' in full_name else full_name
        final_dict[short_id] = clean_name

    # Intelligent Search (Substring matching)
    final_names = []
    available_keys = set(final_dict.keys())
    
    for name in df.index:
        name_str = str(name).strip()
        # Find if any key exists within the current name
        match = next((k for k in available_keys if k in name_str), None)
        final_names.append(final_dict[match] if match else name_str)
        
    df.index = final_names
    print("   Step 2 complete.")
else:
    print("   Annotation file not found. Skipping.")

print("4. Generating Heatmap...")
try:
    # Select Top 50 genes by mean expression
    df['mean'] = df.mean(axis=1)
    df_top = df.sort_values('mean', ascending=False).head(50).drop(columns=['mean'])
    
    # Log transformation
    df_log = np.log1p(df_top)

    # Plot
    plt.figure(figsize=(6, 14)) # Adjusted for better visibility
    sns.heatmap(df_log, cmap='viridis', annot=False,
                yticklabels=True, xticklabels=True, # Show all labels
                cbar_kws={'label': 'Log(RPKM)'}) # Colorbar label

    plt.title("Top 50 Genes - Mean Expression by Group", pad=20) # Title with padding for clarity
    plt.xticks(rotation=45, ha='right', fontsize=12, fontweight='bold') # Rotate x labels for better readability 
    plt.yticks(fontsize=9) # Adjust y label size 
# Save plot 
    out_path = os.path.join(OUTPUT_DIR, "heatmap_groups_clean.png") 
    plt.savefig(out_path, dpi=300, bbox_inches='tight') # Save with tight layout
    print(f"   Success! Saved to: {out_path}") # Indicate success 

except Exception as e: # Catch plotting errors 
    print(f"Plotting error: {e}") # Indicate plotting error