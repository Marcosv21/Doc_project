#!/bin/bash
# Dependencies: Bowtie2, Conda
# Este script irá verificar/criar o ambiente Conda necessário e, em seguida,
# indexar os arquivos de contigs montados pelo MEGAHIT usando Bowtie2.

# --- Seção 1: Configuração Automática do Ambiente ---

# Inicializa o Conda para o script
eval "$(conda shell.bash hook)"

# Define o nome do ambiente necessário (CORREÇÃO 1)
ENV_NAME="Bowtie2"

# Verifica se o ambiente Conda já existe
if ! conda info --envs | grep -q "^${ENV_NAME}\s"; then
    echo "Ambiente Conda '${ENV_NAME}' não encontrado."
    echo "Criando o ambiente e instalando Bowtie2 agora..."
    conda create -n "${ENV_NAME}" -c bioconda bowtie2 -y
    if [ $? -ne 0 ]; then
        echo "ERRO: Falha ao criar o ambiente Conda."
        exit 1
    fi
    echo "Ambiente '${ENV_NAME}' criado e configurado com sucesso."
else
    echo "Ambiente Conda '${ENV_NAME}' encontrado."
fi

# Ativa o ambiente Conda (CORREÇÃO 1)
echo "Ativando o ambiente '${ENV_NAME}'..."
conda activate "${ENV_NAME}"

# --- Seção 2: Execução Principal do Script ---

# Define os diretórios de trabalho
MEGAHIT_DIR="/home/marcos/Teste/MEGAHITS/Megahit_assemblies"
OUTPUT_DIR="/home/marcos/Teste/binning"

echo ""
echo "------------------------------------------------"
echo "Diretório de entrada das montagens: $MEGAHIT_DIR"
echo "Os arquivos de índice serão salvos em: $OUTPUT_DIR"
echo "------------------------------------------------"

mkdir -p "$OUTPUT_DIR"
SAMPLES_FOUND=0

# Loop para procurar por todos os prefixos (SRR, ERR, DRR)
for CONTIGS_PATH in "$MEGAHIT_DIR"/{SRR,ERR,DRR}*; do
    if [ ! -d "$CONTIGS_PATH" ]; then
        continue
    fi
    SAMPLES_FOUND=1
    SAMPLE=$(basename "$CONTIGS_PATH")

    # Define o caminho correto para o arquivo de contigs (CORREÇÃO 2)
    CONTIGS_FILE="$CONTIGS_PATH/final.contigs.fa"

    if [[ -f "$CONTIGS_FILE" ]]; then
        echo "Indexando contigs para a amostra: $SAMPLE..."
        bowtie2-build "$CONTIGS_FILE" "$OUTPUT_DIR/${SAMPLE}_indexed"
        if [[ $? -eq 0 ]]; then
            echo "Indexação concluída para $SAMPLE."
        else
            echo "ERRO ao indexar $SAMPLE."
        fi
    else
        echo "AVISO: Arquivo 'final.contigs.fa' não encontrado em '$CONTIGS_PATH', pulando..."
    fi
done

if [ $SAMPLES_FOUND -eq 0 ]; then
    echo "AVISO: Nenhum diretório de amostra (SRR, ERR, DRR) foi encontrado em '$MEGAHIT_DIR'."
fi

echo ""
echo "Processo de indexação concluído."