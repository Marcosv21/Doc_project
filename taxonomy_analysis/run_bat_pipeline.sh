#!/bin/bash
# Automates CAT_pack (BAT) classification for MetaBAT2 bins

# Activate Conda
eval "$(conda shell.bash hook)"
conda activate cat_env

# --- Configuration ---

# Input/Output Paths
# Adjust paths if necessary
BASE_DIR="/temporario2/17404478/PRJEB59406/filas_processamento/fila_1/gtdb_input_all_bins"
OUT_BASE="/temporario2/17404478/PRJEB59406/filas_processamento/fila_1/BAT_classification"
mkdir -p "$OUT_BASE"

# Database Paths
# Ensure this matches your specific database folder name
DB_BASE="/temporario2/17404478/databases/CAT_data/20240422_CAT_nr"
DB_FOLDER="$DB_BASE/db"
TAX_FOLDER="$DB_BASE/tax"

echo "Starting BAT Classification Pipeline..."

# --- Main Loop ---

for SAMPLE_PATH in "$BASE_DIR"/ERR*; do
    # Skip if not a directory
    [ -d "$SAMPLE_PATH" ] || continue
    
    SAMPLE_NAME=$(basename "$SAMPLE_PATH")
    
    # Locate the specific bins subdirectory
    BIN_SUBDIR=$(find "$SAMPLE_PATH" -maxdepth 1 -type d -name "*metabat-bins*" | head -n 1)

    # Check if bin directory exists
    if [ -n "$BIN_SUBDIR" ] && [ -d "$BIN_SUBDIR" ]; then
        
        # Count .fa files
        count_bins=$(ls "$BIN_SUBDIR"/*.fa 2>/dev/null | wc -l)
        
        # Run pipeline only if bins are present
        if [ "$count_bins" -gt 0 ]; then
            echo "------------------------------------------------"
            echo "Processing Sample: $SAMPLE_NAME"
            echo "Bins found: $count_bins"
            
            # Create output directory
            OUT_DIR="$OUT_BASE/$SAMPLE_NAME"
            mkdir -p "$OUT_DIR"

            # 1. Run BAT (Classification)
            # -n 10: Threads (Adjust if using a job scheduler)
            CAT_pack bins -b "$BIN_SUBDIR" \
                          -d "$DB_FOLDER" \
                          -t "$TAX_FOLDER" \
                          -s .fa \
                          -n 10 \
                          --force \
                          --out_prefix "$OUT_DIR/${SAMPLE_NAME}"

            # 2. Run Add Names (Translation to readable names)
            if [ -f "$OUT_DIR/${SAMPLE_NAME}.bin2classification.txt" ]; then
                echo "  > Generating names report..."
                CAT_pack add_names -i "$OUT_DIR/${SAMPLE_NAME}.bin2classification.txt" \
                                   -o "$OUT_DIR/${SAMPLE_NAME}.bin2classification_NAMES.txt" \
                                   -t "$TAX_FOLDER" \
                                   --only_official
                echo "  > Done."
            else
                echo "  > Error: BAT classification failed (file not found)."
            fi
            
        else
            echo "WARNING: Folder exists for $SAMPLE_NAME but is empty."
        fi
    else
        echo "Skipping $SAMPLE_NAME: No bins folder found."
    fi
done

echo "Pipeline finished."