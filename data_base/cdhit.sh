#!/bin/bash
# Dependencies: CD-HIT
# Install: conda install -c bioconda cdhit

eval "$(conda shell.bash hook)"
conda activate cdhit

INPUT_DIR="/home/marcos/PRJEB59406/Data_base"
OUTPUT_DIR="/home/marcos/PRJEB59406/Data_base/sialidase_families"

mkdir -p "$OUTPUT_DIR"

for FILE in "$INPUT_DIR"/*.fasta; do
    
    [ -e "$FILE" ] || continue

    FAMILY=$(basename "$FILE" .fasta)
    
    echo "------------------------------------------------"
    echo "Processing family: $FAMILY"

    echo "  -> Running CD-HIT to remove redundancy..."
    cd-hit -i "$FILE" -o "$OUTPUT_DIR/nr_${FAMILY} 100.fasta" -c 1.0 -d 0 -n 5 -M 16000 -T 8
    cd-hit -i "$FILE" -o "$OUTPUT_DIR/nr_${FAMILY} 90.fasta" -c 0.9 -d 0 -n 5 -M 16000 -T 8
    cd-hit -i "$FILE" -o "$OUTPUT_DIR/nr_${FAMILY} 80.fasta" -c 0.8 -d 0 -n 4 -M 16000 -T 8
    sed "s/^>/>${FAMILY}_/" "$OUTPUT_DIR/nr_${FAMILY} 100.fasta" > "$OUTPUT_DIR/final_${FAMILY}.fasta"

done

echo "------------------------------------------------"
echo "Merging all non-redundant fasta files into a single file..."

cat "$OUTPUT_DIR"/final_*.fasta > "$OUTPUT_DIR/all_sequences.fasta"

# (Optional) create a datebank DIAMOND
# diamond makedb --in "$OUTPUT_DIR/all_sequences.fasta" -d "$OUTPUT_DIR/all_sequences"

echo "Finish! Database created at: $OUTPUT_DIR/all_sequences.fasta"