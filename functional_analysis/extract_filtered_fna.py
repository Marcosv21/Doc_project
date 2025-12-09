import pandas as pd
from Bio import SeqIO
import glob
import os

# Define directories
DIR_TSV_FILTRADO = "/home/marcos/PRJEB59406/diamond_results_filtrados"
DIR_ORIGINAL_FASTA = "/home/marcos/PRJEB59406/prodigal_outputs"
DIR_OUTPUT = "/home/marcos/PRJEB59406/filtered_fna"
os.makedirs(DIR_OUTPUT, exist_ok=True)
# Get list of filtered TSV files
arquivos_tsv = glob.glob(os.path.join(DIR_TSV_FILTRADO, "*.tsv"))
# Process each TSV file
for arquivo_tsv in arquivos_tsv: # Percorrer cada arquivo TSV na lista
    try: # Tentar executar o bloco de código
        nome_base_tsv = os.path.basename(arquivo_tsv) # Obter o nome base do arquivo TSV
        # Extrair o nome da amostra removendo o sufixo "_matches.tsv" ou a extensão ".tsv"
        if "_matches.tsv" in nome_base_tsv:
            sample_name = nome_base_tsv.replace("_matches.tsv", "") # Remover o sufixo específico
        else: 
            sample_name = os.path.splitext(nome_base_tsv)[0]

        print(f"------------------------------------------------")
        print(f"Sample: {sample_name}")

        arquivo_fna_origem = os.path.join(DIR_ORIGINAL_FASTA, f"{sample_name}.fna") # Caminho do arquivo FNA original
        arquivo_fna_destino = os.path.join(DIR_OUTPUT, f"{sample_name}_filtered.fna") # Caminho do arquivo FNA de saída
# Verificar se o arquivo FNA de origem existe
        if not os.path.exists(arquivo_fna_origem):
            continue
        df = pd.read_csv(arquivo_tsv, sep='\t') # Ler o arquivo TSV em um DataFrame do pandas
        # Obter os IDs alvo da coluna 'seqid' como um conjunto para busca rápida
        ids_alvo = set(df['seqid'].astype(str))
        
        print(f"genes: {len(ids_alvo)}")
# Se nenhum ID alvo for encontrado, pular para a próxima iteração
        if len(ids_alvo) == 0:
            continue

        sequencias_salvas = []
        
        for record in SeqIO.parse(arquivo_fna_origem, "fasta"): # Percorrer cada registro no arquivo FNA original
            id_fasta = record.id.split()[0] # Obter o ID do FASTA (primeira parte antes do espaço)
            
            if id_fasta in ids_alvo: # Verificar se o ID do FASTA está na lista de IDs alvo
                sequencias_salvas.append(record) # Adicionar a sequência à lista de sequências salvas

        if sequencias_salvas: # Se houver sequências salvas, escrevê-las no arquivo de saída
            SeqIO.write(sequencias_salvas, arquivo_fna_destino, "fasta") # Escrever as sequências filtradas no arquivo FNA de saída
        else:
            print("-> ERROR: Sequence not found. Check the ID in TSV if matches of FNA.")

    except Exception as e: # Capturar qualquer exceção que ocorra durante o processamento
        print(f"ERROR {sample_name}: {e}")

print("\nFinish!")