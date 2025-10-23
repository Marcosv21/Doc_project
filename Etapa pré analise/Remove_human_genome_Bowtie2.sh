#!/bin/bash
# Dependencies: Samtools
# Install:
#   conda install -c bioconda samtools

INPUT_DIR =  insira o caminho completo para o diretório de ENTRADA (com os arquivos .sam)

OUTPUT_DIR_BASE = caminho completo para o diretório de SAÍDA (onde os arquivos .fastq serão salvos)

# --- Nome da pasta de saída pré-definido ---
NEW_FOLDER_NAME="Human_genome_removed"
OUTPUT_DIR="${OUTPUT_DIR_BASE}/${NEW_FOLDER_NAME}"

echo "" # Adiciona uma linha em branco para melhor visualização
echo "Diretório de entrada definido como: $INPUT_DIR"
echo "Diretório de saída definido como: $OUTPUT_DIR"
echo "------------------------------------------------"
echo ""

# Script to extract only the unaligned sequences with the human genome and convert them back to FASTQ, separating forward and reverse

# Cria o diretório de saída, se ele não existir
mkdir -p "$OUTPUT_DIR"

# Processing
for SAM_FILE in "$INPUT_DIR"/*.sam; do
  BASENAME=$(basename "$SAM_FILE" .sam)
  
  echo "Processando o arquivo: ${BASENAME}.sam"
  
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
echo "Processamento concluído para todos os arquivos!"
