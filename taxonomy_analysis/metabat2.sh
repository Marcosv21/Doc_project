#!/bin/bash
# Dependencies: MetaBat2
# Install: conda install bioconda::metabat2

eval "$(conda shell.bash hook)"
conda activate metabat2

# Directories
MEGAHIT_DIR="/home/marcos/PRJEB59406/megahit_assemblies"
BAM_DIR="/home/marcos/PRJEB59406/ordened_bams"
OUTPUT_DIR="/home/marcos/PRJEB59406/MetaBAT2_bins"

# Create the output directory
mkdir -p "$OUTPUT_DIR"

# Loop through samples
for SAMPLE_DIR in "$MEGAHIT_DIR"/ERR*; do
    SAMPLE_NAME=$(basename "$SAMPLE_DIR")
    
    # MegaHIT standard output filename
    CONTIGS_FILE="$SAMPLE_DIR/final.contigs.fa"
    
    # Define expected BAM filename
    BAM_FILE="$BAM_DIR/${SAMPLE_NAME}_aligned_sorted.bam"

    if [[ -f "$CONTIGS_FILE" && -f "$BAM_FILE" ]]; then
        echo "Running MetaBAT for $SAMPLE_NAME"
        
        # Create specific output subdirectory
        SAMPLE_OUTPUT="$OUTPUT_DIR/$SAMPLE_NAME"
        mkdir -p "$SAMPLE_OUTPUT"
        
        # Change to output directory (runMetaBat writes to current dir)
        cd "$SAMPLE_OUTPUT"
        
        # Execute MetaBAT2
        runMetaBat.sh -m 1500 "$CONTIGS_FILE" "$BAM_FILE"
        
        # Return to original directory
        cd - > /dev/null
        
    else
        echo "Missing files for $SAMPLE_NAME:"
        [ ! -f "$CONTIGS_FILE" ] && echo "  - Contigs not found: $CONTIGS_FILE"
        [ ! -f "$BAM_FILE" ] && echo "  - BAM not found: $BAM_FILE"
        echo "Skipping..."
    fi
done