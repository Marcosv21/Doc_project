#!/bin/bash

# --- CONFIGURATION ---
BASE_DIR="/temporario2/17404478/PRJEB59406"
INPUT_DIR="$BASE_DIR/filas_processamento"
OUTPUT_DIR="$BASE_DIR/ORGANIZED_RESULTS"

# Define items to compress for each category
FUNCTIONAL_LIST=("idxstats" "diamond_results_filtrados")
TAXONOMY_LIST=("gtdb_input_all_bins" "mag_annotation" "BAT_classification" "taxonomy_gtdb" "filtered_bins_high_quality")

# --- MAIN EXECUTION ---
echo "=== Starting Organization and Compression ==="
echo "Source: $INPUT_DIR"
echo "Target: $OUTPUT_DIR"

# 1. Create main directories
mkdir -p "$OUTPUT_DIR/functional"
mkdir -p "$OUTPUT_DIR/taxonomy"

# 2. Handle sample_map.csv (Single File)
if [ -f "$BASE_DIR/sample_map.csv" ]; then
    echo "Compressing sample_map.csv..."
    gzip -c "$BASE_DIR/sample_map.csv" > "$OUTPUT_DIR/functional/sample_map.csv.gz"
else
    echo "Warning: sample_map.csv not found."
fi

# 3. Process Queues (fila_*)
for queue_path in "$INPUT_DIR"/fila_*; do
    queue_name=$(basename "$queue_path")
    echo "Processing: $queue_name"

    # Create subdirectories for the current queue
    mkdir -p "$OUTPUT_DIR/functional/$queue_name"
    mkdir -p "$OUTPUT_DIR/taxonomy/$queue_name"

    # Function to compress items
    compress_items() {
        local category=$1
        shift
        local items=("${@}") # Array of items to process

        for item in "${items[@]}"; do
            # Check if file or directory exists
            if [ -e "$queue_path/$item" ]; then
                # Tar/Gzip to destination without full path (-C changes dir first)
                tar -czf "$OUTPUT_DIR/$category/$queue_name/$item.tar.gz" -C "$queue_path" "$item"
            else
                echo "   [Skipped] $item not found in $queue_name"
            fi
        done
    }

    # Run compression for both lists
    compress_items "functional" "${FUNCTIONAL_LIST[@]}"
    compress_items "taxonomy"   "${TAXONOMY_LIST[@]}"

done

echo "=== Done! Output saved to: $OUTPUT_DIR ==="