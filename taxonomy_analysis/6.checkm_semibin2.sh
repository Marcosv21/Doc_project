#!/bin/bash

eval "$(conda shell.bash hook)"
conda activate checkm

BASE_DIR="/temporario2/17404478/PRJNA46333_2/assay/semibin2/final_bins"
OUT_BASE="/temporario2/17404478/PRJNA46333_2/checkm_results_semibin2"

mkdir -p "$OUT_BASE"

echo "Starting CheckM Pipeline for SemiBin2..."
for SAMPLE_PATH in "$BASE_DIR"/*; do
    [ -d "$SAMPLE_PATH" ] || continue
    SAMPLE_NAME=$(basename "$SAMPLE_PATH")
    BIN_SUBDIR="$SAMPLE_PATH/output_bins"

    if [ -d "$BIN_SUBDIR" ]; then
        echo "Sample: $SAMPLE_NAME - Unzipping bins..."
        gunzip -f "$BIN_SUBDIR"/*.fa.gz 2>/dev/null || true

        count_bins=$(ls "$BIN_SUBDIR"/*.fa 2>/dev/null | wc -l)

        if [ "$count_bins" -gt 0 ]; then
            echo "Processing $SAMPLE_NAME - Bins found: $count_bins"
            OUT_DIR="$OUT_BASE/$SAMPLE_NAME"

            mkdir -p "$OUT_DIR"

            checkm lineage_wf -t 10 --pplacer_threads 2 -x fa "$BIN_SUBDIR" "$OUT_DIR"

            if [ -f "$OUT_DIR/lineage.ms" ]; then
                echo "  > Generating QA reports..."
                checkm qa "$OUT_DIR/lineage.ms" "$OUT_DIR" > "$OUT_DIR/quality_report.txt"
                checkm qa "$OUT_DIR/lineage.ms" "$OUT_DIR" --tab_table -f "$OUT_DIR/quality_table.tsv"
                echo "  > Done."

            fi
        else
            echo "WARNING: No bins found in $BIN_SUBDIR (check if gunzip worked)."
        fi
    else

        echo "Skipping $SAMPLE_NAME: output_bins folder not found."
    fi

done
echo "Pipeline finished."
