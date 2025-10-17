#!/bin/bash
# Dependencies: FLASH
# Install:
#   conda install -c bioconda flash

# --- Início da Seção Interativa ---
echo "--- Configuração de Caminhos para o Script FLASH ---"

# Pede ao usuário para inserir o diretório de entrada com os arquivos FASTQ
read -p "Por favor, insira o caminho completo para o diretório de ENTRADA (com os arquivos .fastq): " FASTQ_PATH

# Pede ao usuário para inserir o diretório de SAÍDA principal
read -p "Agora, insira o caminho para o diretório de SAÍDA principal: " OUTPUT_PATH_BASE
# --- Fim da Seção Interativa ---

# Define o nome da pasta de saída de forma automática
NEW_FOLDER_NAME="Merged_reads"

# Junta o caminho base com o nome da nova pasta para criar o caminho de saída final
OUTPUT_PATH="${OUTPUT_PATH_BASE}/${NEW_FOLDER_NAME}"

echo ""
echo "Diretório de entrada definido como: $FASTQ_PATH"
echo "Os arquivos de saída serão salvos em: $OUTPUT_PATH"
echo "------------------------------------------------"
echo ""

# Cria o diretório de saída se ele não existir
echo "Criando diretório de saída em ${OUTPUT_PATH}..."
mkdir -p "$OUTPUT_PATH"

# Loop through all *_R1.fastq files in the FASTQ_PATH
for FILE1 in "$FASTQ_PATH"/*_R1.fastq; do
  # Get the base name of the sample (remove the _R1.fastq suffix)
  BASENAME=$(basename "$FILE1" _R1.fastq)

  # Define the corresponding file for the _R2.fastq pair
  FILE2="${FASTQ_PATH}/${BASENAME}_R2.fastq"

  # Check if the _R2.fastq file exists
  if [ -f "$FILE2" ]; then
    # Merging with FLASH
    flash -m 20 -M 150 --to-stdout "$FILE1" "$FILE2" > "${OUTPUT_PATH}/${BASENAME}.merged.fastq" 
    # -m 20: based on the minimum merge of fastp, which is 30, and the default of FLASH, which is 10.
    # -M 150: avoids the WARNING from FLASH saying that many sequences overlap more than the parameter, but it didn't change the merge percentage
  else
    echo "Pair for file $FILE1 not found: $FILE2" >&2
  fi
done
