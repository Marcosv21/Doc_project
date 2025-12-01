import os
import pandas as pd

# Load the idxstats file and keep only CDS and abundance columns
def load_idxstats(path):
    df= pd.read_csv(path, sep='\t')
    df= df[['CDS','Abundance']]
    return df

# Load the DIAMOND alignment file and rename columns for consistency
def load_diamond(path):
    df = pd.read_csv(path, sep ='\t')
    df = df[['qseqid', 'sseqid']]
    df.rename (columns={'qseqid':'CDS','sseqid':'Protein'},inplace= True )
    return df

# Merge abundance data with DIAMOND hits across all samples
def merge_data(idxstats_dir, diamond_dir, output_file):
    all_samples = []
    
    for file in os.listdir(idxstats_dir):
        if file.endswith(".idxstats.txt"):
            sample = file.split(".")[0]
            idxstats_path = os.path.join(idxstats_dir, file)
            diamond_path = os.path.join(diamond_dir, f"{sample}_matches.tsv")
            
            if os.path.exists(diamond_path):
                df_idx = load_idxstats(idxstats_path)
                df_diamond = load_diamond(diamond_path)
                
                # Merge DIAMOND hits with abundance values based on CDS
                df_merged = df_diamond.merge(df_idx, on='CDS', how='left')
                df_merged['Sample'] = sample
                all_samples.append(df_merged)
            else:
                print(f"[Warning] Diamond file not found for {sample}")
    
    # Combine all merged dataframes into one
    final_df = pd.concat(all_samples, ignore_index=True)
    final_df.to_csv(output_file, sep='\t', index=False)
    print(f"Unified data saved to: {output_file}")

# Define input/output paths
idxstats_path = "/home/gabrielacastilho/idxstats/"
diamond_path = "/home/gabrielacastilho/outputs_diamond/"
output_path = "unified_data.tsv"

# Run the merge
merge_data(idxstats_path, diamond_path, output_path)

#Add group to the unified file

# File paths
unified_file = "/content/drive/MyDrive/Doutorado/dados_unificados.tsv"
samples_file = "/content/drive/MyDrive/Doutorado/amostras.csv"
output_file = "/content/drive/MyDrive/Doutorado/dados_unificados_com_grupo.tsv"

# Load the unified data table 
df_unified = pd.read_csv(unified_file, sep='\t')

# Load the sample metadata file   # This file must contain a mapping between each sample ID and its corresponding group (e.g., Disease or Control)
df_samples= pd.read_csv(samples_file)
df_samples.rename (columns= {'Run Accession': 'Sample', 'AMYLOID': 'Group'}, inplace=True)

# Merge group information into the unified table
df_final= df_unified.merge(df_samples ['Sample','Group'], on='Sample', how='left')

# Save the final table with group information added
df_final.to_csv(output_file, sep='\t', index=False)
print(f"Data saved to: {output_file}")