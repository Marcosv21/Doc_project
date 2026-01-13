#!/bin/bash
# Dependencies: diamond
# Install: conda install -c bioconda diamond

eval "$(conda shell.bash hook)"
conda activate diamond

INPUT_DIR="/home/marcos/PRJEB59406/data_base1"

OUTPUT_DIR="/home/marcos/PRJEB59406/data_base1/diamond_db"
mkdir -p "$OUTPUT_DIR"

echo "Starting header modification and database creation..."

for file in "$INPUT_DIR"/*.fasta; do
    
    [ -e "$file" ] || continue

    filename=$(basename "$file" .fasta)
    
    family=${nr_}

    mod_file="$OUTPUT_DIR/mod_${family}.fasta"

    sed "s/^>/>${family}./" "$file" > "$mod_file"

    echo "Processing: $family -> $mod_file"
done

cat "$OUTPUT_DIR"/mod_*.fasta > "$OUTPUT_DIR/all_sequences.fasta"
diamond makedb --in "$OUTPUT_DIR/all_sequences.fasta" -d "$OUTPUT_DIR/all_sequences"
echo "Databank in: $OUTPUT_DIR/all_sequences.dmnd"

rm "$OUTPUT_DIR"/mod_*.fasta