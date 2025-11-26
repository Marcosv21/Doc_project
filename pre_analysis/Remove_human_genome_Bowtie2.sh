#!/bin/bash
# Dependencies: Samtools
# Install:
#   conda install -c bioconda samtools
# 1. Start Conda environment initialization
set -e
eval "$(conda shell.bash hook)"

# Activate environment
echo "Activating env samtools..."
conda activate samtools
# Define paths
INPUT_DIR="/temporario2/17404478/PRJEB59406/code/bowtie2_aligned"
OUTPUT_DIR="/temporario2/17404478/PRJEB59406/code/cleaned_reads"
# Create output directory if it does not exist
mkdir -p "$OUTPUT_DIR"
# Processing
for SAM_FILE in "$INPUT_DIR"/*.sam; do
  BASENAME=$(basename "$SAM_FILE" .sam)

  echo "Processing archive: ${BASENAME}.sam"
  
  # Convert and filter SAM -> BAM
  samtools view -@ 8 -b -f 12 -F 256 "$SAM_FILE" > "$OUTPUT_DIR/${BASENAME}_filtered.bam" 
  # @8 usa 8 threads, -f 12 garante que apenas as leituras onde nem a primária (flag 4) nem o seu par (flag 8) estão alinhados sejam mantidas.
  # -F 256 exclui alinhamentos secundários, que geralmente não são úteis para análises básicas.
  # Opções de filtragem: -f (requer flags): ter todas as flags presentes, -F (exclui flags): não ter nenhuma das flags presentes.

  # Convert BAM to FASTQ
  samtools fastq -@ 8 -1 "$OUTPUT_DIR/${BASENAME}_R1.fastq" -2 "$OUTPUT_DIR/${BASENAME}_R2.fastq" "$OUTPUT_DIR/${BASENAME}_filtered.bam"
  
  echo "Arquivos ${BASENAME}_R1.fastq e ${BASENAME}_R2.fastq criados com sucesso."

  # Remove intermediate file (optional)
  rm "$OUTPUT_DIR/${BASENAME}_filtered.bam"
done

echo ""
echo "Finished processing all files!"
