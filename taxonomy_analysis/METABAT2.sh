#!/bin/bash
# Dependencies: MetaBat2, Samtools, Conda
# Este script unificado:
# 1. Converte arquivos .sam em .bam ordenados (se ainda não tiverem sido convertidos).
# 2. Executa o MetaBat2 para realizar o binning.

# --- Seção 2: Definição dos Caminhos ---
# (Estes caminhos são baseados nos seus logs de erro)

# 1. Saída do MEGAHIT (Contém os contigs)
MEGAHIT_DIR="/home/marcos/Teste/MEGAHITS/Megahit_assemblies"

# 2. Saída do Alinhamento (Contém os arquivos .sam)
SAM_DIR="/home/marcos/Teste/binning/Contigs_reads_aligned"

# 3. Onde os .bam ordenados serão guardados
BAM_DIR="/home/marcos/Teste/binning/Sorted_BAMs"

# 4. Onde as pastas de bins (saída do MetaBat2) serão guardadas
METABAT_OUTPUT_DIR="/home/marcos/Teste/binning/MetaBat2_bins"

# Cria os diretórios de saída, se não existirem
mkdir -p "$BAM_DIR"
mkdir -p "$METABAT_OUTPUT_DIR"

echo "------------------------------------------------"
echo "Iniciando o pipeline de Binning (MetaBat2)..."

# --- Seção 3: Loop Principal (Baseado no diretório do MEGAHIT) ---

for ASSEMBLY_PATH in "$MEGAHIT_DIR"/{SRR,ERR,DRR}*_assembly; do
    
    # Verifica se a pasta da amostra existe
    if [ ! -d "$ASSEMBLY_PATH" ]; then
        continue # Pula se não encontrar pastas com os prefixos
    fi
    
    # Extrai o ID da amostra (ex: SRR8509869) do nome da pasta
    SAMPLE_ID=$(basename "$ASSEMBLY_PATH" | sed 's/_assembly//')

    # Define os caminhos dos arquivos necessários para esta amostra
    CONTIGS_FILE="$ASSEMBLY_PATH/final.contigs.fa"
    SAM_FILE="$SAM_DIR/${SAMPLE_ID}_aligned.sam"
    SORTED_BAM_FILE="$BAM_DIR/${SAMPLE_ID}_sorted.bam"
    
    # --- Bloco de Conversão SAM -> BAM (se necessário) ---
    
    # Verifica se o arquivo .BAM ordenado final NÃO existe
    if [ ! -f "$SORTED_BAM_FILE" ]; then
        echo "Arquivo BAM ordenado para $SAMPLE_ID não encontrado. Criando agora..."
        
        # Verifica se o arquivo .SAM de origem existe
        if [ -f "$SAM_FILE" ]; then
            # Define um nome para o BAM temporário (não ordenado)
            UNSORTED_BAM_FILE="$BAM_DIR/${SAMPLE_ID}_unsorted.bam"
            
            # 1. Converter SAM para BAM
            samtools view -S -b "$SAM_FILE" > "$UNSORTED_BAM_FILE"
            
            if [ $? -eq 0 ]; then
                # 2. Ordenar o BAM
                echo "Ordenando BAM para $SAMPLE_ID..."
                samtools sort "$UNSORTED_BAM_FILE" -o "$SORTED_BAM_FILE" -@ 8 # Usando 8 threads
                
                if [ $? -eq 0 ]; then
                    echo "BAM ordenado criado: $SORTED_BAM_FILE"
                    # 3. Limpar arquivos intermediários
                    rm -f "$UNSORTED_BAM_FILE"
                else
                    echo "ERRO: Falha ao ordenar o BAM para $SAMPLE_ID. Pulando."
                    rm -f "$UNSORTED_BAM_FILE"
                    continue
                fi
            else
                echo "ERRO: Falha ao converter SAM para BAM para $SAMPLE_ID. Pulando."
                continue
            fi
        else
            echo "AVISO: Arquivo SAM de origem ($SAM_FILE) não encontrado. Não é possível criar o BAM. Pulando $SAMPLE_ID."
            continue
        fi
    else
        echo "Arquivo BAM ordenado para $SAMPLE_ID já existe."
    fi
    # --- Fim do Bloco de Conversão ---


    # --- Execução do MetaBat2 ---
    
    # Define o diretório de saída para os bins desta amostra
    BINS_DIR="$METABAT_OUTPUT_DIR/${SAMPLE_ID}_bins"
    mkdir -p "$BINS_DIR"
    
    echo "Executando MetaBAT2 para $SAMPLE_ID..."
    
    metabat2 -i "$CONTIGS_FILE" -a "$SORTED_BAM_FILE" -o "$BINS_DIR/bin" -m 1500 -t 8 # -m 1500 (mínimo de 1500bp), -t 8 (8 threads)
    
    if [ $? -ne 0 ]; then
        echo "ERRO: MetaBat2 falhou para a amostra ${SAMPLE_ID}."
    else
        echo "MetaBat2 concluído para ${SAMPLE_ID}."
    fi
    
done

echo ""
echo "Processo de Binning concluído para todas as amostras!"
