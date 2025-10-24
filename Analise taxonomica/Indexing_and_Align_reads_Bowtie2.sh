#!/bin/bash
# Dependencies: Bowtie2, Conda
# Este script alinha leituras pareadas (FASTQ) contra um índice de referência
# usando o Bowtie2. Ele irá verificar/criar o ambiente Conda necessário.

#Indexing------------------------------------------------------------------------
#Activate the Conda environment (if needed)
eval "$(conda shell.bash hook)"
conda activate bowtie2_env

# Directories
MEGAHIT_DIR="Caminho/megahit_outputs"
OUTPUT_DIR="Caminho/indexed_contigs"

# Create the output directory if it doesn't exist
mkdir -p "$OUTPUT_DIR"

# Loop through the samples
for CONTIGS_PATH in "$MEGAHIT_DIR"/ERR*; do
    # Get the sample name from the folder name
    SAMPLE=$(basename "$CONTIGS_PATH")
    CONTIGS_FILE="$CONTIGS_PATH/${SAMPLE}.final.contigs.fa"

    # Check if the contigs file exists
    if [[ -f "$CONTIGS_FILE" ]]; then
        echo "Indexing $SAMPLE..."

        # Index the contigs
        bowtie2-build "$CONTIGS_FILE" "$OUTPUT_DIR/${SAMPLE}_indexed"

        # Check if the command was successful
        if [[ $? -eq 0 ]]; then
            echo "Indexing completed for $SAMPLE."
        else
            echo "Error indexing $SAMPLE."
        fi
    else
        echo "Contigs file not found for $SAMPLE, skipping..."
    fi

#------------------------------------------------------------------------
FASTQ_PATH = "o caminho para o diretório com os reads limpos (FASTQ): "
INDEX_PATH = "$OUTPUT_DIR"
OUTPUT_PATH_BASE = "o caminho para o diretório de SAÍDA principal: "

# --- Seção 3: Execução Principal ---

# Cria uma pasta de saída específica para os alinhamentos
NEW_FOLDER_NAME="Contigs_reads_aligned"
OUTPUT_PATH="${OUTPUT_PATH_BASE}/${NEW_FOLDER_NAME}"

echo ""
echo "Diretório de leituras: $FASTQ_PATH"
echo "Diretório de índices: $INDEX_PATH"
echo "Os alinhamentos (.sam) serão salvos em: $OUTPUT_PATH"
echo "------------------------------------------------"

mkdir -p "$OUTPUT_PATH"

# Loop para processar todos os arquivos *_R1.fastq
for FILE1 in "$FASTQ_PATH"/*_R1.fastq; do
  [ -e "$FILE1" ] || { echo "AVISO: Nenhum arquivo *_R1.fastq encontrado. Saindo."; exit 1; }
  
  # Obtém o nome base da amostra de forma mais robusta
  BASENAME=$(basename "$FILE1" _R1.fastq)

  # Define os caminhos dos arquivos para a amostra atual
  FILE2="${FASTQ_PATH}/${BASENAME}_R2.fastq"
  INDEX_FILE="${INDEX_PATH}/${BASENAME}_indexed"

  # Verifica se TODOS os arquivos necessários existem antes de continuar
  if [ ! -f "$FILE2" ]; then
      echo "AVISO: Arquivo par $FILE2 não encontrado. Pulando a amostra $BASENAME."
      continue # Pula para a próxima iteração do loop
  fi
  if [ ! -f "${INDEX_FILE}.1.bt2" ]; then # Verifica a existência do primeiro arquivo de índice
      echo "AVISO: Arquivo de índice para ${INDEX_FILE} não encontrado. Pulando a amostra $BASENAME."
      continue
  fi

  echo "Processando alinhamento para: $BASENAME"

  # Alinhamento com Bowtie2
  bowtie2 -x "$INDEX_FILE" \
    -1 "$FILE1" \
    -2 "$FILE2" \
    --threads 8 \
    -S "$OUTPUT_PATH/${BASENAME}_aligned.sam"

  # Verificação de erro do Bowtie2
  if [ $? -ne 0 ]; then
      echo "ERRO: O alinhamento com Bowtie2 falhou para a amostra ${BASENAME}. Abortando."
      exit 1
  fi
done

echo ""
echo "Processo de alinhamento concluído!"
