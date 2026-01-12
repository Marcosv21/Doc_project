# Do you need to install Biopython? If so, run: pip install biopython pandas
import pandas as pd
from Bio import SeqIO
import glob
import os

# Define directories
DIR_TSV_FILTRED = "/home/marcos/PRJEB59406/diamond_results_filtrados"
DIR_FASTA = "/home/marcos/PRJEB59406/prodigal_outputs"
DIR_OUTPUT = "/home/marcos/PRJEB59406/filtered_fna"
os.makedirs(DIR_OUTPUT, exist_ok=True)
# Get list of filtered TSV files
tsv_archives = glob.glob(os.path.join(DIR_TSV_FILTRED, "*.tsv"))
# Process each TSV file
for tsv_files in tsv_archives: 
    try: 
        base_name_tsv = os.path.basename(tsv_files) 
        # Extract sample name
        if "_matches.tsv" in base_name_tsv:
            sample_name = base_name_tsv.replace("_matches.tsv", "") 
        else: 
            sample_name = os.path.splitext(base_name_tsv)[0]

        print(f"------------------------------------------------")
        print(f"Sample: {sample_name}")
# Define paths for original and destination FNA files
        fna_arc_org = os.path.join(DIR_FASTA, f"{sample_name}.fna") 
        dest_fna_arc = os.path.join(DIR_OUTPUT, f"{sample_name}_filtered.fna") 
        if not os.path.exists(fna_arc_org):
            continue
        df = pd.read_csv(tsv_files, sep='\t') 
        target_id = set(df['seqid'].astype(str))
        
        print(f"genes: {len(target_id)}")
        if len(target_id) == 0:
            continue
# Extract and save filtered sequences 
        saves_sequence = []
        # Read original FNA and filter sequences 
        for record in SeqIO.parse(dest_fna_arc, "fasta"): 
            id_fasta = record.id.split()[0] 
            # Check if the sequence ID is in the target IDs
            if id_fasta in target_id: 
                saves_sequence.append(record) 
# Write filtered sequences to new FNA file 
        if saves_sequence: 
            SeqIO.write(saves_sequence, dest_fna_arc, "fasta") 
        else:
            print("-> ERROR: Sequence not found. Check the ID in TSV if matches of FNA.")
# Error handling 
    except Exception as e: 
        print(f"ERROR {sample_name}: {e}")

print("\nFinish!")