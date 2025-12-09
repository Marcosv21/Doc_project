import pandas as pd
import glob
import os
# Define the column names for the DIAMOND output TSV files
columns = [
    'seqid','sseqid','pident','length','mismatch','gapopen',
    'qstart','qend','sstart','send','evalue','bitscore','qlen','slen'
]
# Define input and output directories
INPUT_DIR = "/home/marcos/PRJEB59406/diamond_results"
OUTPUT_DIR = "/home/marcos/PRJEB59406/diamond_results_filtrados"
os.makedirs(OUTPUT_DIR, exist_ok=True)
# Get list of TSV files in the input directory
document = glob.glob(os.path.join(INPUT_DIR, "*.tsv"))
# Process each TSV file
for arc in document: # Percorrer cada arquivo TSV na lista
    base_name = os.path.basename(document) # Obter o nome base do arquivo
    print(f"-> Processing: {base_name}") # Indicar o arquivo em processamento
    
    try: # Tentar executar o bloco de código
        df = pd.read_csv(arc, sep="\t", names=columns, header=None, # Ler o arquivo TSV em um DataFrame do pandas
                         usecols=range(14), low_memory=False) # Usar apenas as primeiras 14 colunas
        # Converter colunas numéricas para o tipo apropriado
        cols_num = ['pident', 'length', 'evalue', 'bitscore', 'qlen', 'slen']
        
        for col in cols_num: # Percorrer cada coluna numérica
            df[col] = pd.to_numeric(df[col], errors='coerce')
# Remover linhas com valores NaN nas colunas numéricas            
        before_line = len(df) # Contar o número de linhas antes da remoção de NaNs
        df = df.dropna(subset=cols_num) # Remover linhas com NaN nas colunas numéricas
        # Verificar se o DataFrame está vazio após a remoção de NaNs
        if len(df) == 0: # Se o DataFrame estiver vazio
            continue # Pular para a próxima iteração

        df['cobertura'] = df['length'] / df['qlen'] # Calcular a cobertura do alinhamento
        df['qlen/slen'] = df['qlen'] / df['slen'] # Calcular a razão entre o comprimento da query e o comprimento do sujeito
# Aplicar os filtros especificados
        filter = (
            (df['pident'] >= 40) &
            (df['evalue'] <= 1e-4) &
            (df['cobertura'] >= 0.5) &
            (df['qlen/slen'] >= 0.7) &
            (df['qlen/slen'] <= 1.5) &
            (df['bitscore'] >= 50)
        )
        
        final_df = df[filter] # Aplicar o filtro ao DataFrame

        output_pat = os.path.join(OUTPUT_DIR, base_name) # Definir o caminho do arquivo de saída
        final_df.to_csv(output_pat, sep="\t", index=False) # Salvar o DataFrame filtrado em um arquivo TSV
# Indicar o número de linhas antes e depois da filtragem
    except Exception as e: # Capturar qualquer exceção que ocorra durante o processamento
        print(f"   ERROR IN {base_name}: {e}") # Imprimir a mensagem de erro

print("Finish!")