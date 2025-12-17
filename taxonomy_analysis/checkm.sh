#!/bin/bash

# Dependencies: CheckM
# Install: conda create -n checkm -c bioconda checkm-genome

# Activate conda environment
eval "$(conda shell.bash hook)"
conda activate checkm

# Base path containing MetaBAT2 bins
BASE_DIR="/home/marcos/PRJEB59406/MetaBAT2_bins"

# Output directory
OUT_BASE="/home/marcos/PRJEB59406/checkm_results"
mkdir -p "$OUT_BASE"

echo "Starting CheckM..."

# Loop through sample directories (ERR...)
for SAMPLE_PATH in "$BASE_DIR"/ERR*; do
    if [ -d "$SAMPLE_PATH" ]; then
        SAMPLE_NAME=$(basename "$SAMPLE_PATH")
        
        # Find the subdirectory containing "metabat-bins"
        BIN_SUBDIR=$(find "$SAMPLE_PATH" -maxdepth 1 -type d -name "*metabat-bins*" | head -n 1)

        if [ -n "$BIN_SUBDIR" ] && [ -d "$BIN_SUBDIR" ]; then
            
            # Count how many .fa files exist INSIDE the subdirectory
            count_bins=$(ls "$BIN_SUBDIR"/*.fa 2>/dev/null | wc -l)
            
            if [ "$count_bins" -gt 0 ]; then
                echo "------------------------------------------------"
                echo "Sample: $SAMPLE_NAME"
                echo "Bins folder found: $(basename "$BIN_SUBDIR")"
                echo "Number of bins: $count_bins"
                
                # Define specific output directory
                OUT_DIR="$OUT_BASE/$SAMPLE_NAME"
                mkdir -p "$OUT_DIR"

                # Run CheckM pointing to the correct SUBDIRECTORY
                # -x fa: MetaBAT2 generates .fa files by default
                checkm lineage_wf -t 4 --pplacer_threads 1 -x fa "$BIN_SUBDIR" "$OUT_DIR"
                
            else
                echo "WARNING: MetaBAT folder exists for $SAMPLE_NAME, but is empty (0 bins)."
            fi
        else
            echo "ERROR: Could not find 'metabat-bins' subdirectory inside $SAMPLE_NAME"
        fi
    fi
done

echo "CheckM finished."