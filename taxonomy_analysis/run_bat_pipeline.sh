#!/bin/bash
# Automates CAT_pack (BAT) with HEADER RENAMING to fix duplicates

# 1. Activate Conda
eval "$(conda shell.bash hook)"
conda activate cat_env

ORIGINAL_BINS="/temporario2/17404478/PRJEB59406/filas_processamento/fila_1/filtered_bins_high_quality"

OUT_DIR="/temporario2/17404478/PRJEB59406/filas_processamento/fila_1/BAT_classification"
mkdir -p "$OUT_DIR"

TEMP_BINS="$OUT_DIR/temp_renamed_bins"
mkdir -p "$TEMP_BINS"

DB_BASE="/temporario2/17404478/PRJEB59406/code/data_base/CAT_data/20241212_CAT_nr_website"
DB_FOLDER="$DB_BASE/db"
TAX_FOLDER="$DB_BASE/tax"

OUTPUT_PREFIX="$OUT_DIR/all_bins"

cp "$ORIGINAL_BINS"/*.fa "$TEMP_BINS/"

for FILE in "$TEMP_BINS"/*.fa; do
    BASENAME=$(basename "$FILE" .fa)
    
    sed -i "s/^>/>${BASENAME}_/" "$FILE"
done

echo "   Headers renamed successfully."

count_bins=$(ls "$TEMP_BINS"/*.fa 2>/dev/null | wc -l)

if [ "$count_bins" -gt 0 ]; then
    echo "Found $count_bins bins. Running CAT_pack..."

    CAT_pack bins -b "$TEMP_BINS" \
                  -d "$DB_FOLDER" \
                  -t "$TAX_FOLDER" \
                  -s .fa \
                  -n 20 \
                  --force \
                  --out_prefix "$OUTPUT_PREFIX"

    if [ -f "${OUTPUT_PREFIX}.bin2classification.txt" ]; then
        echo "  > Generating readable names..."
        
        CAT_pack add_names -i "${OUTPUT_PREFIX}.bin2classification.txt" \
                           -o "${OUTPUT_PREFIX}.bin2classification_NAMES.txt" \
                           -t "$TAX_FOLDER" \
                           --only_official
        
        echo "  > Done! Check: ${OUTPUT_PREFIX}.bin2classification_NAMES.txt"
    else
        echo "  > Error: BAT did not generate the classification file."
    fi

else
    echo "ERROR: No bins found in temp folder."
fi

echo "Cleaning up temp files..."
rm -rf "$TEMP_BINS"

echo "Pipeline finished."