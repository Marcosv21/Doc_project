#!/bin/bash
# Dependencies: Samtools
# Install: conda install -c bioconda samtools

eval "$(conda shell.bash hook)"
conda activate samtools  

INPUT_DIR="/home/marcos/PRJEB59406/fna_reads_aligned"
STATS_DIR="/home/marcos/PRJEB59406/idxstats"

mkdir -p "$STATS_DIR"

for SAM_FILE in "$INPUT_DIR"/*.sam; do
    
    [ -e "$SAM_FILE" ] || continue

    BASENAME=$(basename "$SAM_FILE" .sam) 
    BAM_FILE="${INPUT_DIR}/${BASENAME}_sorted.bam"
    
    echo "Processing: $BASENAME"

    if [ ! -f "$BAM_FILE" ]; then
        echo "Converting and orderind BAM..."
        samtools sort -@ 8 -o "$BAM_FILE" "$SAM_FILE"
    else
        echo "  -> BAM order existing yet."
    fi

    if [ ! -f "${BAM_FILE}.bai" ]; then
        echo "  -> Index..."
        samtools index "$BAM_FILE"
    fi

    echo "Idxstats..."
    samtools idxstats "$BAM_FILE" > "${STATS_DIR}/${BASENAME}.idxstats.txt"

    # Opcional: Remove SAM archives to save space
    rm "$SAM_FILE"
    echo "SAM removed."

done

echo "Well done! Statistical base save in: $STATS_DIR"