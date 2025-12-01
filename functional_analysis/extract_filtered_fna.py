import pandas as pd
from Bio import SeqIO
import glob
import os


DIR_TSV_FILTRADO = "/home/marcos/PRJEB59406/diamond_results_filtrados"
DIR_ORIGINAL_FASTA = "/home/marcos/PRJEB59406/prodigal_outputs"
DIR_OUTPUT = "/home/marcos/PRJEB59406/filtered_fna"
os.makedirs(DIR_OUTPUT, exist_ok=True)

arquivos_tsv = glob.glob(os.path.join(DIR_TSV_FILTRADO, "*.tsv"))

for arquivo_tsv in arquivos_tsv:
    try:
        nome_base_tsv = os.path.basename(arquivo_tsv)
        
        if "_matches.tsv" in nome_base_tsv:
            sample_name = nome_base_tsv.replace("_matches.tsv", "")
        else:
            sample_name = os.path.splitext(nome_base_tsv)[0]

        print(f"------------------------------------------------")
        print(f"Sample: {sample_name}")

        arquivo_fna_origem = os.path.join(DIR_ORIGINAL_FASTA, f"{sample_name}.fna")
        arquivo_fna_destino = os.path.join(DIR_OUTPUT, f"{sample_name}_filtered.fna")

        if not os.path.exists(arquivo_fna_origem):
            continue
        df = pd.read_csv(arquivo_tsv, sep='\t')
        
        ids_alvo = set(df['seqid'].astype(str))
        
        print(f"genes: {len(ids_alvo)}")

        if len(ids_alvo) == 0:
            continue

        sequencias_salvas = []
        
        for record in SeqIO.parse(arquivo_fna_origem, "fasta"):
            id_fasta = record.id.split()[0] 
            
            if id_fasta in ids_alvo:
                sequencias_salvas.append(record)

        if sequencias_salvas:
            SeqIO.write(sequencias_salvas, arquivo_fna_destino, "fasta")
        else:
            print("-> ERROR: Sequence not found. Check the ID in TSV if matches of FNA.")

    except Exception as e:
        print(f"ERROR {sample_name}: {e}")

print("\nFinish!")