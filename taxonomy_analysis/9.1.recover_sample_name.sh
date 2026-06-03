#!/bin/bash

BINS_DIR="/temporario2/17404478/PRJNA46333_2/assay/filtered_bins_high_quality"

OUTPUT="/temporario2/17404478/PRJNA46333_2/mag_sample_mapping.tsv"

echo -e "MAG\tDominant_Sample\tNum_Contigs" > "$OUTPUT"

for bin in "$BINS_DIR"/*.fa; do

    MAG=$(basename "$bin")

    SAMPLE_INFO=$(grep "^>" "$bin" \
        | sed 's/^>//' \
        | cut -d'_' -f1 \
        | sort \
        | uniq -c \
        | sort -nr \
        | head -1)

    COUNT=$(echo "$SAMPLE_INFO" | awk '{print $1}')
    SAMPLE=$(echo "$SAMPLE_INFO" | awk '{print $2}')

    echo -e "${MAG}\t${SAMPLE}\t${COUNT}" >> "$OUTPUT"

done

echo "Done: $OUTPUT"