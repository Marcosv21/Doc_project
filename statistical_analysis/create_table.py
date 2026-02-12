import pandas as pd
import glob
import os

# --- CONFIGURATION ---
PATH_BINS = "/temporario2/17404478/PRJEB59406/filas_processamento/fila_*/gtdb_input_all_bins/*.fa"
PATH_DIAMOND = "/temporario2/17404478/PRJEB59406/filas_processamento/fila_*/mag_annotation/diamond_matches/*.tsv"
FILE_ABUNDANCE = "/temporario2/17404478/PRJEB59406/table/unified_abundance_with_groups.tsv"
FILE_TAXONOMY = "/temporario2/17404478/PRJEB59406/table/master_table_mag_sialidase_gtdb.csv"

# Output files
OUTPUT_DETAILED = "/temporario2/17404478/PRJEB59406/ORGANIZED_RESULTS/Final_Pathway_Table_Detailed.tsv"
OUTPUT_MATRIX = "/temporario2/17404478/PRJEB59406/ORGANIZED_RESULTS/Final_Pathway_Matrix_MAGs.tsv"

df_abund = pd.read_csv(FILE_ABUNDANCE, sep='\t')
id_col = df_abund.columns[0]
# Fix IDs (remove extra underscores if necessary)
df_abund['Contig_Match_ID'] = df_abund[id_col].astype(str).apply(lambda x: x.rsplit('_', 1)[0] if '_' in x else x)

# 2. MAP CONTIGS TO BINS
print("2. Mapping Contigs to Bins...")
contig_to_bin = {}
fasta_files = glob.glob(PATH_BINS)

for fasta in fasta_files:
    bin_name = os.path.basename(fasta).replace('.fa', '').replace('.fasta', '')
    with open(fasta, 'r') as f:
        for line in f:
            if line.startswith('>'):
                contig_id = line.split()[0].replace('>', '')
                contig_to_bin[contig_id] = bin_name

df_abund['mag_id'] = df_abund['Contig_Match_ID'].map(contig_to_bin)

# 3. LOAD DIAMOND (EXTRACT FUNCTIONS)
print("3. Loading Diamond & Extracting Tags...")
diamond_files = glob.glob(PATH_DIAMOND)
df_blast_list = []

for f in diamond_files:
    if os.path.isfile(f) and os.path.getsize(f) > 0:
        try:
            tmp = pd.read_csv(f, sep='\t', usecols=[0, 1], names=['Contig_ID', 'Subject_ID'])
            df_blast_list.append(tmp)
        except: pass

if df_blast_list:
    df_blast = pd.concat(df_blast_list, ignore_index=True)
    
    # SPLIT LOGIC: "nanH|A0A123" -> Gene="nanH", Ref="A0A123"
    split_data = df_blast['Subject_ID'].str.split('|', n=1, expand=True)
    
    if split_data.shape[1] == 2:
        df_blast['Gene_Function'] = split_data[0]
        df_blast['Ref_ID'] = split_data[1]
    else:
        df_blast['Gene_Function'] = 'Unknown'

    df_blast = df_blast.drop_duplicates(subset=['Contig_ID'])
    
    # Merge abundance + function
    df_merged = pd.merge(df_abund, df_blast, left_on=id_col, right_on='Contig_ID', how='left')
else:
    print("   [ERROR] No Diamond matches found.")
    df_merged = df_abund

# 4. LOAD TAXONOMY
print("4. Loading Taxonomy...")
if os.path.exists(FILE_TAXONOMY):
    df_tax = pd.read_csv(FILE_TAXONOMY, sep='\t')
    bin_col_tax = next((c for c in ['mag_id', 'user_genome', 'Bin_Id', 'genome'] if c in df_tax.columns), None)
    
    if bin_col_tax:
        df_tax[bin_col_tax] = df_tax[bin_col_tax].astype(str).str.strip()
        # Merge taxonomy into main table
        df_final = pd.merge(df_merged, df_tax, left_on='mag_id', right_on=bin_col_tax, how='left')
    else:
        df_final = df_merged
else:
    df_final = df_merged

# Save Detailed Table
df_final.to_csv(OUTPUT_DETAILED, sep='\t', index=False)
print(f"   -> Detailed table saved: {OUTPUT_DETAILED}")

df_genes = df_final.dropna(subset=['Gene_Function', 'mag_id'])

if not df_genes.empty:
    df_matrix = pd.crosstab(df_genes['mag_id'], df_genes['Gene_Function'])

    if 'Phylum' in df_final.columns and 'Genus' in df_final.columns:
        tax_map = df_final[['mag_id', 'Phylum', 'Genus', 'Species']].drop_duplicates('mag_id').set_index('mag_id')
        df_matrix = df_matrix.join(tax_map)

    core_genes = ['nanA', 'nanE', 'nanK', 'nanH', 'nanT']
    
    for gene in core_genes:
        if gene not in df_matrix.columns:
            df_matrix[gene] = 0

    df_matrix['Total_Pathway_Genes'] = 0
    for gene in core_genes:
         df_matrix['Total_Pathway_Genes'] += (df_matrix[gene] > 0).astype(int)

    df_matrix.to_csv(OUTPUT_MATRIX, sep='\t')
    print(f"   -> Matrix saved: {OUTPUT_MATRIX}")
    
    print("\n   [PREVIEW OF MATRIX]")
    print(df_matrix.head())

else:
    print("   [WARNING] No genes found to build matrix.")

print("="*30)