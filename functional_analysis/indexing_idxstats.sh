#!/bin/bash

# Activate environment
eval "$(conda shell.bash hook)"
conda activate bowtie2

# Define paths
INPUT_DIR="/temporario2/17404478/PRJEB59406/filas_processamento/fila_1/fna_reads_aligned"
OUTPUT_DIR="/temporario2/17404478/PRJEB59406/filas_processamento/fila_1/idxstats"

mkdir -p "$OUTPUT_DIR"

# Process files
for sam_file in "$INPUT_DIR"/*.sam; do
    # Check if file exists
    [ -e "$sam_file" ] || continue

    base_name=$(basename "$sam_file" .sam)
    bam_file="${INPUT_DIR}/${base_name}.sorted.bam"

    echo "-> Processing: $base_name"

    # 1. Convert SAM to sorted BAM (8 threads)
    samtools sort -@ 8 -o "$bam_file" "$sam_file"

    # 2. Index BAM
    samtools index "$bam_file"

    # 3. Generate Statistics
    samtools idxstats "$bam_file" > "$OUTPUT_DIR/${base_name}.idxstats.txt"

    # 4. Remove original SAM to save space (Safety check: only if BAM was created)
    if [ -s "$bam_file" ]; then
        rm "$sam_file"
    fi
done

echo "Done! Statistics saved in: $OUTPUT_DIR"