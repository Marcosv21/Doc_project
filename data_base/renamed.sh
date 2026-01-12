#!/bin/bash
#SBATCH --job-name=diamond_annot
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=16
#SBATCH --mem=64G
#SBATCH --time=24:00:00

# 1. Ativa o ambiente (crie um se não tiver: conda create -n diamond diamond)
eval "$(conda shell.bash hook)"
conda activate diamond  # Ou o nome do seu env

# 2. Definição de Caminhos
# O arquivo fasta com os genes "códigos próprios" da sua amiga
INPUT_FASTA="/home/marcos/PRJEB59406/nanH_without_extra_signatures.fasta"

# Onde salvar o resultado
OUTPUT_FILE="/home/marcos/PRJEB59406/resultado_anotacao.tsv"

# Banco de dados (Você precisa ter um banco formatado. O SwissProt é ótimo para começar pois é curado)
# Se não tiver, pode baixar e formatar:
#wget ftp://ftp.uniprot.org/pub/databases/uniprot/current_release/knowledgebase/complete/uniprot_sprot.fasta.gz
#diamond makedb --in uniprot_sprot.fasta.gz -d swiss_prot
DB_PATH="/home/marcos/PRJEB59406/bancos_dados/swiss_prot/swiss_prot"

echo "Rodando DIAMOND BLASTP..."

# 3. Execução (blastp se for proteína, blastx se for DNA)
diamond blastp \
    --db "$DB_PATH" \
    --query "$INPUT_FASTA" \
    --out "$OUTPUT_FILE" \
    --outfmt 6 qseqid sseqid pident length mismatch gapopen qstart qend sstart send evalue bitscore stitle \
    --sensitive \
    --max-target-seqs 1 \
    --evalue 1e-5 \
    --threads 16

echo "Pronto! Veja a coluna 'stitle' no arquivo de saída para ver os nomes reais."