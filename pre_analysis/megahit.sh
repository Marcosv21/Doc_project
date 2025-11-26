#!/bin/bash
# Dependencies: MEGAHIT
# Install:
#   conda install -c bioconda megahit
eval "$(conda shell.bash hook)"

# 3. Activate environment
echo "activate env megahit..."
conda activate megahit

FASTQ_PATH="/home/marcos/PRJEB59406/cleaned_reads" 
MERGED_PATH="/home/marcos/PRJEB59406/flash_merged_reads" 
OUTPUT_PATH="/home/marcos/PRJEB59406/megahit_assemblies"

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
