import pandas as pd
import seaborn as sns
import matplotlib.pyplot as plt
import numpy as np
import os
# Define file paths and directories
BASE_DIR = "/home/marcos/PRJEB59406"
FILE_TPM = f"{BASE_DIR}/abundance_results/rpkm_matrix.tsv" 
OUTPUT_DIR = f"{BASE_DIR}/abundance_results"
FILE_SAMPLE_MAP = f"{BASE_DIR}/sample_map.csv"
# Create output directory if it doesn't exist
df = pd.read_csv(FILE_TPM, sep="\t", index_col="gene_id") # Read RPKM matrix

gene_example = df.index[0] # Get an example gene ID

if "_" not in str(gene_example) and "k141" in str(gene_example): # Check gene ID format
    print("   Warning.") 

if os.path.exists(FILE_SAMPLE_MAP): # Check if sample map file exists
    try: # Load sample map and rename columns
        sample_map = pd.read_csv(FILE_SAMPLE_MAP, header=None, index_col=0)[1].to_dict() # Read sample map into a dictionary
        df = df.rename(columns=sample_map) # Rename DataFrame columns using sample map
    except Exception as e: # Catch any exceptions that occur during processing
        print(f"ERROR sample_map: {e}") # Print error message
else:
    print("\n2. Sample map not found. Proceeding with original column names.\n")

file_out = os.path.join(OUTPUT_DIR, "rpkm_matrix_final.tsv") # Define output file path
df.to_csv(file_out, sep="\t") # Save updated RPKM matrix

try: # Generate heatmap for top 50 genes
    df['mean'] = df.mean(axis=1) # Calculate mean RPKM for each gene
    df_top = df.sort_values(by='mean', ascending=False).head(50).drop(columns=['mean']) # Select top 50 genes by mean RPKM

    df_log = np.log1p(df_top) # Apply log transformation

    plt.figure(figsize=(14, 16)) # Set figure size
    
    g = sns.clustermap(df_log, 
                       method='ward', 
                       cmap='viridis', 
                       metric='euclidean',
                       figsize=(14, 16), 
                       dendrogram_ratio=(.1, .2), 
                       cbar_pos=(0, .2, .03, .4)) # Create clustered heatmap

    g.ax_heatmap.set_title(f"Top {50} Genes (RPKM abundance)", pad=100) # Set heatmap title
    # Customize tick labels
    plt.setp(g.ax_heatmap.get_xticklabels(), rotation=45, ha="right", fontsize=10) # Rotate x-axis labels
    plt.setp(g.ax_heatmap.get_yticklabels(), rotation=0, fontsize=8) # Set y-axis label properties
# Save heatmap image
    img_out = os.path.join(OUTPUT_DIR, "heatmap_final.png") # Define output image path
    plt.savefig(img_out, dpi=300, bbox_inches='tight') # Save figure
    print(f"   Finish! You image in {img_out}") # Indicate completion

except Exception as e: # Catch any exceptions that occur during processing
    print(f"   ERROR: {e}")