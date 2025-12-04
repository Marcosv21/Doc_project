#!/bin/bash
# Dependencies: diamond
# Install: conda install -c bioconda diamond

eval "$(conda shell.bash hook)"
conda activate diamond

INPUT_DIR="/home/marcos/PRJEB59406/Data_base/sialidase_families"
OUTPUT_DIR="/home/marcos/PRJEB59406/Data_base/diamond_db_named"
mkdir -p "$OUTPUT_DIR"

MERGED_FASTA="$OUTPUT_DIR/all_sequences_named.fasta"

rm -f "$MERGED_FASTA"
touch "$MERGED_FASTA"

echo "1. STARTING PROCESS AND FUSION ARCHIVES..."

for FILE in "$INPUT_DIR"/*.fasta; do
    
    [ -e "$FILE" ] || continue

    BASENAME=$(basename "$FILE")
    FAMILY_NAME=$(echo "$BASENAME" | sed -E 's/nr_//; s/final_//; s/\.fasta//')

    sed "s/^>/>${FAMILY_NAME}_/" "$FILE" >> "$MERGED_FASTA"

done

diamond makedb --in "$MERGED_FASTA" -d "$OUTPUT_DIR/all_sequences_named"

echo "------------------------------------------------"
echo "FINISH!"
echo "DATA BANK IN: $OUTPUT_DIR/all_sequences_named.dmnd"
