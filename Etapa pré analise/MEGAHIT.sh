#!/bin/bash
# Dependencies: MEGAHIT
# Install:
#   conda install -c bioconda megahit

# --- Início da Seção Interativa ---
echo "--- Configuração de Caminhos para o Script MEGAHIT ---"

# Pede ao usuário para inserir os caminhos de entrada
read -p "Insira o caminho para o diretório com as leituras PAREADAS (ex: *_R1.fastq): " FASTQ_PATH
read -p "Insira o caminho para o diretório com as leituras UNIDAS (do FLASH): " MERGED_PATH
read -p "Insira o caminho para o diretório de SAÍDA principal: " OUTPUT_PATH_BASE
# --- Fim da Seção Interativa ---

# Define o nome da pasta de saída de forma automática
NEW_FOLDER_NAME="Megahit_assemblies"

# Junta o caminho base com o nome da nova pasta para criar o caminho de saída final
OUTPUT_PATH="${OUTPUT_PATH_BASE}/${NEW_FOLDER_NAME}"

echo ""
echo "Diretório de leituras pareadas: $FASTQ_PATH"
echo "Diretório de leituras unidas: $MERGED_PATH"
echo "Os resultados da montagem serão salvos em: $OUTPUT_PATH"
echo "------------------------------------------------"
echo ""

# Cria o diretório de saída se ele não existir
echo "Criando diretório de saída em ${OUTPUT_PATH}..."
mkdir -p "$OUTPUT_PATH"

#Loop to proccess all files in FASTQ_PATH
for FILE1 in "$FASTQ_PATH"/*_R1.fastq; do
  # Obtain the basename of the sample (remove sufix _filtered_aligned_R1. fastq)
  BASENAME=$(basename "$FILE1" _filtered_aligned_R1.fastq)

  # Define the pair file _filtered_aligned_R2.fastq
  FILE2="${FASTQ_PATH}/${BASENAME}_filtered_aligned_R2.fastq"
  
  #Define the merged file 
  FILE3="${MERGED_PATH}/${BASENAME}_filtered_aligned.merged.fastq"
  
  #Assembling with MEGAHIT
  megahit -1 "$FILE1" -2 "$FILE2" -r "$FILE3" -o "$OUTPUT_PATH/${BASENAME}"
done
