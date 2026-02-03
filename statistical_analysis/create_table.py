import pandas as pd
import glob
import os

PATH_BINS = "/temporario2/17404478/PRJEB59406/filas_processamento/fila_*/gtdb_input_all_bins/*.fa"
PATH_DIAMOND = "/temporario2/17404478/PRJEB59406/filas_processamento/fila_*/mag_annotation/diamond_matches/*"
FILE_ABUNDANCE = "/temporario2/17404478/PRJEB59406/results/unified_abundance_with_groups.tsv"
FILE_TAXONOMY = "/temporario2/17404478/PRJEB59406/results/master_table_mag_sialidase.tsv"
OUTPUT_FILE = "/temporario2/17404478/PRJEB59406/results/Final_Table_Taxonomy_Function.tsv"

print("1. Loading Abundance Data...")
df_abund = pd.read_csv(FILE_ABUNDANCE, sep='\t')

id_col = df_abund.columns[0]
print(f"   -> Using column '{id_col}' as Gene ID (Ex: {df_abund[id_col].iloc[0]})")

df_abund['Contig_Match_ID'] = df_abund[id_col].astype(str).apply(lambda x: x.rsplit('_', 1)[0] if '_' in x else x)

print(f"   -> Gene IDs prepared. Matching Key: {df_abund['Contig_Match_ID'].iloc[0]}")

print("2. Mapping Contigs to Bins...")

contig_to_bin = {}
fasta_files = glob.glob(PATH_BINS)

if not fasta_files:
    raise FileNotFoundError("No .fa files found for Bins.")

for fasta in fasta_files:
    bin_name = os.path.basename(fasta).replace('.fa', '')
    
    with open(fasta, 'r') as f:
        for line in f:
            if line.startswith('>'):
                contig_id = line.split()[0].replace('>', '')
                contig_to_bin[contig_id] = bin_name

df_abund['mag_id'] = df_abund['Contig_Match_ID'].map(contig_to_bin)

found_bins = df_abund['mag_id'].notna().sum()
print(f"   -> {found_bins} genes successfully linked to a Bin directly.")

print("3. Loading Diamond (for annotation reference)...")
diamond_files = glob.glob(PATH_DIAMOND)
df_blast_list = []

for f in diamond_files:
    if os.path.isfile(f):
        try:
            tmp = pd.read_csv(f, sep='\t', usecols=[0, 1], names=['Contig_ID', 'Gene_Ref_ID'])
            df_blast_list.append(tmp)
        except:
            pass

if df_blast_list:
    df_blast = pd.concat(df_blast_list, ignore_index=True)
    df_blast = df_blast.drop_duplicates(subset=['Contig_ID'])
    
    df_merged = pd.merge(df_abund, df_blast, left_on='Contig_Match_ID', right_on='Contig_ID', how='left')
else:
    print("   [WARNING] Diamond files not loaded. Proceeding without specific gene annotation.")
    df_merged = df_abund

print("4. Merging with Taxonomy...")

df_tax = pd.read_csv(FILE_TAXONOMY, sep='\t')

bin_col = next(c for c in ['mag_id', 'user_genome', 'Bin_Id'] if c in df_tax.columns)
df_tax[bin_col] = df_tax[bin_col].astype(str).str.strip()

df_final = pd.merge(df_merged, df_tax, left_on='mag_id', right_on=bin_col, how='left')

df_final_valid = df_final.dropna(subset=['Phylum'])

df_final.to_csv(OUTPUT_FILE, sep='\t', index=False)

print("\n" + "="*30)
print(f"DONE! File saved to: {OUTPUT_FILE}")
print(f"Total Genes Processed: {len(df_abund)}")
print(f"Genes with Taxonomy:   {len(df_final_valid)}")
print("="*30)

if len(df_final_valid) == 0:
    print("DEBUG: Still empty? Check if 'Contig_Match_ID' matches the keys in 'contig_to_bin'.")
    print(f"Abundance Key Example: {df_abund['Contig_Match_ID'].iloc[0]}")
    if contig_to_bin:
        print(f"Bin Map Key Example:   {list(contig_to_bin.keys())[0]}")