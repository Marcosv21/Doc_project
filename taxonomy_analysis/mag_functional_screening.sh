#!/bin/bash
# Dependências: Prodigal, Diamond
# Instalação: conda install prodigal diamond

eval "$(conda shell.bash hook)"
conda activate diamond  # At the moment diamond and prodigal are in the same environment

MAGS_DIR="/home/marcos/PRJEB59406/metabat2_bins/final_bins"

OUTPUT_DIR="/home/marcos/PRJEB59406/mag_annotation"
PROTEINS_DIR="$OUTPUT_DIR/proteins"
DIAMOND_OUT="$OUTPUT_DIR/diamond_matches"

DB_PATH="/home/marcos/PRJEB59406/Data_base/sialidase_families/all_sequences.dmnd"

mkdir -p "$PROTEINS_DIR"
mkdir -p "$DIAMOND_OUT"

for MAG in "$MAGS_DIR"/*.fa; do
    BIN_NAME=$(basename "$MAG" .fa)
    
    echo "Processing MAG: $BIN_NAME"
    prodigal -i "$MAG" \
             -a "$PROTEINS_DIR/${BIN_NAME}.faa" \
             -o "$PROTEINS_DIR/${BIN_NAME}.gff" \
             -p meta -q

    diamond blastp -d "$DB_PATH" \
                   -q "$PROTEINS_DIR/${BIN_NAME}.faa" \
                   -o "$DIAMOND_OUT/${BIN_NAME}_hits_sial.tsv" \
                   --outfmt 6 qseqid sseqid pident length mismatch gapopen qstart qend sstart send evalue bitscore \
                   --mid-sensitive \
                   --quiet

    # 3. Verification of hits
    if [ -s "$DIAMOND_OUT/${BIN_NAME}_hits_sial.tsv" ]; then
        echo " Found sialidase in $BIN_NAME!"
    fi
done
