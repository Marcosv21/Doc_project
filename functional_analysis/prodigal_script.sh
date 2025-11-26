#!/bin/bash
# Dependencies: Prodigal
# Install:
# conda install bioconda::prodigal

eval "$(conda shell.bash hook)"
conda activate prodigal
#path to folders
MEGAHIT_DIR="/home/marcos/PRJEB59406/megahit_assemblies"
OUTPUT_DIR="/home/marcos/PRJEB59406/prodigal_outputs"

mkdir -p $OUTPUT_DIR

# Loop through samples
for CONTIGS_PATH in "$MEGAHIT_DIR"/ERR*; do
    
    [ -e "$CONTIGS_PATH" ] || continue

    SAMPLE=$(basename "$CONTIGS_PATH")
    
    CONTIGS_FILE="$CONTIGS_PATH/final.contigs.fa"

    if [ ! -f "$CONTIGS_FILE" ]; then
        echo "WARNING: contings archive not found for $SAMPLE ($CONTIGS_FILE)"
        continue
    fi

    echo "Running Prodigal for $SAMPLE"

    prodigal -i "$CONTIGS_FILE" \
             -o "$OUTPUT_DIR/${SAMPLE}.gff" \
             -a "$OUTPUT_DIR/${SAMPLE}.faa" \
             -d "$OUTPUT_DIR/${SAMPLE}.fna" \
             -p meta

done

echo "Prodigal finished!"