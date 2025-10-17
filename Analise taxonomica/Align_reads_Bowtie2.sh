#!/bin/bash
# Dependencies: Bowtie2, Conda
# Este script alinha leituras pareadas (FASTQ) contra um índice de referência
# usando o Bowtie2. Ele irá verificar/criar o ambiente Conda necessário.

# --- Seção 1: Configuração Automática do Ambiente ---

# Inicializa o Conda para o script
eval "$(conda shell.bash hook)"

# Define o nome do ambiente necessário
ENV_NAME="Bowtie2" # Você pode mudar este nome se preferir

# Verifica se o ambiente Conda já existe
if ! conda info --envs | grep -q "^${ENV_NAME}\s"; then
    echo "Ambiente Conda '${ENV_NAME}' não encontrado."
    echo "Criando o ambiente e instalando Bowtie2 agora..."
    
    # Cria o ambiente e instala o bowtie2 do canal bioconda
    conda create -n "${ENV_NAME}" -c bioconda bowtie2 -y
    
    # Verifica se a criação foi bem-sucedida
    if [ $? -ne 0 ]; then
        echo "ERRO: Falha ao criar o ambiente Conda. Verifique sua instalação."
        exit 1
    fi
    echo "Ambiente '${ENV_NAME}' criado e configurado com sucesso."
else
    echo "Ambiente Conda '${ENV_NAME}' encontrado."
fi

# Ativa o ambiente Conda
echo "Ativando o ambiente '${ENV_NAME}'..."
conda activate "${ENV_NAME}"

# --- Seção 2: Entrada do Usuário ---

echo ""
echo "--- Configuração de Caminhos para o Alinhamento com Bowtie2 ---"
read -p "Insira o caminho para o diretório com os reads limpos (FASTQ): " FASTQ_PATH
read -p "Insira o caminho para o diretório com os contigs/genomas indexados: " INDEX_PATH
read -p "Insira o caminho para o diretório de SAÍDA principal: " OUTPUT_PATH_BASE

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
