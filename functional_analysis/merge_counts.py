import pandas as pd
import glob
import os
# Define input and output directories
INPUT_DIR = "/home/marcos/PRJEB59406/idxstats"
OUTPUT_DIR = "/home/marcos/PRJEB59406/abundance_results"
os.makedirs(OUTPUT_DIR, exist_ok=True) # Criar diretório de saída se não existir
archives = glob.glob(os.path.join(INPUT_DIR, "*.idxstats.txt")) # Obter lista de arquivos idxstats
# Inicializar dicionários para armazenar contagens e tamanhos
cont = {} # Dicionário para contagens
size = {} # Dicionário para tamanhos de genes
# Processar cada arquivo idxstats
for arquivo in archives: # Percorrer cada arquivo na lista
    basename = os.path.basename(arquivo) # Obter o nome base do arquivo
    sample_name = basename.replace(".idxstats.txt", "").replace("_aligned_fna", "") # Extrair nome da amostra
    # Indicar o arquivo em processamento
    print(f"Lendo: {sample_name}")
    
    try: # Tentar executar o bloco de código
        df = pd.read_csv(arquivo, sep="\t", header=None, names=['gene_id', 'length', 'mapped', 'unmapped']) # Ler o arquivo idxstats em um DataFrame do pandas
        
        df = df[df['gene_id'] != '*'] # Remover linhas com gene_id '*'
        
        dict_actual_size = df.set_index('gene_id')['length'].to_dict() # Criar dicionário de tamanhos de genes
        size.update(dict_actual_size) # Atualizar dicionário de tamanhos com os novos valores
        
        cont[sample_name] = df.groupby('gene_id')['mapped'].sum() # Agrupar por gene_id e somar as contagens mapeadas
        
    except Exception as e: # Capturar qualquer exceção que ocorra durante o processamento
        print(f"ERROR IN {sample_name}: {e}") # Imprimir a mensagem de erro


df_counts = pd.DataFrame(cont) # Criar DataFrame de contagens a partir do dicionário

df_counts = df_counts.fillna(0).astype(int) # Substituir NaN por 0 e converter para inteiros

df_lengths = pd.DataFrame.from_dict(size, orient='index', columns=['length']) # Criar DataFrame de tamanhos de genes

commun_genes = df_counts.index.intersection(df_lengths.index) # Encontrar genes comuns entre contagens e tamanhos
df_counts = df_counts.loc[commun_genes] #  Filtrar ambos DataFrames para incluir apenas genes comuns 
df_lengths = df_lengths.loc[commun_genes] # Filtrar ambos DataFrames para incluir apenas genes comuns 

file_counts = os.path.join(OUTPUT_DIR, "raw_counts_matrix.tsv") # Salvar matriz de contagens brutas em arquivo TSV
df_counts.to_csv(file_counts, sep="\t", index_label="gene_id") 

file_lengths = os.path.join(OUTPUT_DIR, "gene_lengths.tsv") # Salvar tamanhos de genes em arquivo TSV
df_lengths.to_csv(file_lengths, sep="\t", index_label="gene_id") 

print(f"Sucess!, genes id total: {len(df_counts)}") 