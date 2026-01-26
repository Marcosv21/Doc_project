#!/bin/bash
# Automates CheckM lineage_wf and qa for MetaBAT2 bins

# Activate Conda
eval "$(conda shell.bash hook)"
conda activate checkm

# Paths
BASE_DIR="/home/marcos/PRJEB59406/MetaBAT2_bins"
OUT_BASE="/home/marcos/PRJEB59406/checkm_results"
mkdir -p "$OUT_BASE"

echo "Starting CheckM Pipeline..."

# Iterate through samples
for SAMPLE_PATH in "$BASE_DIR"/ERR*; do
    # Skip if not a directory
    [ -d "$SAMPLE_PATH" ] || continue
    
    SAMPLE_NAME=$(basename "$SAMPLE_PATH")
    
    # Find the specific bins subdirectory
    BIN_SUBDIR=$(find "$SAMPLE_PATH" -maxdepth 1 -type d -name "*metabat-bins*" | head -n 1)

    # 1. Check if bin directory exists
    if [ -n "$BIN_SUBDIR" ] && [ -d "$BIN_SUBDIR" ]; then
        
        # 2. Count how many .fa files exist INSIDE the subdirectory
        count_bins=$(ls "$BIN_SUBDIR"/*.fa 2>/dev/null | wc -l)
        
        # 3. Proceed only if there are bins present
        if [ "$count_bins" -gt 0 ]; then
            echo "------------------------------------------------"
            echo "Processing Sample: $SAMPLE_NAME"
            echo "Bins folder: $(basename "$BIN_SUBDIR")"
            echo "Bins found: $count_bins"
            
            # Define specific output directory
            OUT_DIR="$OUT_BASE/$SAMPLE_NAME"
            mkdir -p "$OUT_DIR"

            # 4. Run Main Workflow
            # -x fa: MetaBAT2 generates .fa files
            # -t 4: Use 4 threads for CheckM. Adjust as needed.
            # --pplacer_threads 1: Use 1 thread for pplacer step. Adjust as needed.
            checkm lineage_wf -t 4 --pplacer_threads 1 -x fa "$BIN_SUBDIR" "$OUT_DIR"

            # 5. Generate QA Reports (Txt and Tsv)
            if [ -f "$OUT_DIR/lineage.ms" ]; then
                echo "  > Generating QA reports..."
                checkm qa "$OUT_DIR/lineage.ms" "$OUT_DIR" > "$OUT_DIR/quality_report.txt" # Text report
                checkm qa "$OUT_DIR/lineage.ms" "$OUT_DIR" --tab_table -f "$OUT_DIR/quality_table.tsv" # TSV report 
                echo "  > Done."
            else
                echo "  > Error: CheckM lineage_wf failed (lineage.ms not found)."
            fi
            
        else
            echo "WARNING: MetaBAT folder exists for $SAMPLE_NAME, but is empty (0 bins)."
        fi
    else
        echo "Skipping $SAMPLE_NAME: No bins folder found."
    fi
done

echo "Pipeline finished."