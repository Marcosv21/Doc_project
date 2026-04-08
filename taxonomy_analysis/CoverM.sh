#!/bin/bash

# Initialize Conda and activate environment
eval "$(conda shell.bash hook)"
conda activate coverm_env

# Configuration
BASE_DIR="/temporario2/17404478/PRJNA46333/assay"
THREADS=8

echo "Starting CoverM processing..."

# Loop through directories
for WORK_DIR in "$BASE_DIR"; do
    echo "----------------------------------"
    echo "Processing: $WORK_DIR"
    echo "----------------------------------"

    # Define paths
    BINS_DIR="$WORK_DIR/filtered_bins_high_quality"
    BAM_DIR="$WORK_DIR/ordened_bams"
    OUT_DIR="$WORK_DIR/coverm_results"

    # Validation: Ensure required directories exist
    if [[ ! -d "$BINS_DIR" || ! -d "$BAM_DIR" ]]; then
        echo "Error: Required directories (bins or bams) missing in $WORK_DIR. Skipping..."
        continue
    fi

    # Gather BAM files into an array
    BAM_FILES=("$BAM_DIR"/*.bam)
    if [[ ! -f "${BAM_FILES[0]}" ]]; then
        echo "Error: No BAM files found in $BAM_DIR. Skipping..."
        continue
    fi

    mkdir -p "$OUT_DIR"

    # Run CoverM
    coverm genome \
      --genome-fasta-directory "$BINS_DIR" \
      --genome-extension fa \
      --bam-files "${BAM_FILES[@]}" \
      --threads "$THREADS" \
      --methods relative_abundance \
      --min-read-aligned-percent 0.75 \
      --min-read-percent-identity 0.95 \
      --output-file "$OUT_DIR/mag_abundance.tsv"

    echo "Finished: $WORK_DIR"
done

echo "ALL PROCESSES COMPLETED"