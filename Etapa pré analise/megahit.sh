#!/bin/bash
# Dependencies: MEGAHIT
# Install:
#   conda install -c bioconda megahit
eval "$(conda shell.bash hook)"

# 2. Checks if the 'fastp_env' environment 
if conda info --envs | grep -q "^megahit"; then
    echo "Env 'megahit' already exists."
else
    echo "env create 'megahit'..."
    conda create -y -n megahit
    conda install -c megahit
fi

# 3. Activate environment
echo "activate env megahit..."
conda activate megahit

FASTQ_PATH = "Insira o caminho para o diretório com as leituras PAREADAS (ex: *_R1.fastq)" 
MERGED_PATH = "Insira o caminho para o diretório com as leituras UNIDAS (do FLASH) " 
OUTPUT_PATH_BASE = "Insira o caminho para o diretório de SAÍDA principal"

NEW_FOLDER_NAME="megahit_assemblies"

OUTPUT_PATH="${OUTPUT_PATH_BASE}/${NEW_FOLDER_NAME}"
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
