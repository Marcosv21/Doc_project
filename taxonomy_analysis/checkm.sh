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

        if [ -n "$BIN_SUBDIR" ] && [ -d "$BIN_SUBDIR" ]; then
            
            # Count how many .fa files exist INSIDE the subdirectory
            count_bins=$(ls "$BIN_SUBDIR"/*.fa 2>/dev/null | wc -l)
            # Proceed only if there are bins present
            if [ "$count_bins" -gt 0 ]; then
                echo "------------------------------------------------"
                echo "Sample: $SAMPLE_NAME"
                echo "Bins folder found: $(basename "$BIN_SUBDIR")"
                echo "Number of bins: $count_bins"
                
                # Define specific output directory
                OUT_DIR="$OUT_BASE/$SAMPLE_NAME"
                mkdir -p "$OUT_DIR"
    # Check if directory exists and contains .fa files
    if [ -n "$BIN_SUBDIR" ] && ls "$BIN_SUBDIR"/*.fa 1> /dev/null 2>&1; then
        echo "Processing Sample: $SAMPLE_NAME"
        
        OUT_DIR="$OUT_BASE/$SAMPLE_NAME"
        mkdir -p "$OUT_DIR"

                # Run CheckM pointing to the correct SUBDIRECTORY
                # -x fa: MetaBAT2 generates .fa files by default
                # Using 4 threads for analysis and 1 thread for pplacer
                # Adjust threads as needed based on your system capabilities
                checkm lineage_wf -t 4 --pplacer_threads 1 -x fa "$BIN_SUBDIR" "$OUT_DIR"
                
            else
                echo "WARNING: MetaBAT folder exists for $SAMPLE_NAME, but is empty (0 bins)."
            fi
        # 1. Run Main Workflow
        checkm lineage_wf -t 4 --pplacer_threads 1 -x fa "$BIN_SUBDIR" "$OUT_DIR"

        # 2. Generate QA Reports (Txt and Tsv)
        if [ -f "$OUT_DIR/lineage.ms" ]; then
            checkm qa "$OUT_DIR/lineage.ms" "$OUT_DIR" > "$OUT_DIR/quality_report.txt"
            checkm qa "$OUT_DIR/lineage.ms" "$OUT_DIR" --tab_table -f "$OUT_DIR/quality_table.tsv"
            echo "  > Quality reports saved."
        else
            echo "  > Error: Lineage workflow failed."
        fi
    else
        echo "Skipping $SAMPLE_NAME: No bins found."
    fi
done

echo "Pipeline finished."
