#!/bin/bash
# Dependencies: MetaBat2
# Install:
# conda install bioconda::metabat2

eval "$(conda shell.bash hook)"
conda activate metabat2

#Specify pathways to contigs files, ordered bam files and runMetaBat.sh *this file comes with the installation of MetaBat2 
MEGAHIT_DIR="/home/marcos/PRJEB59406/megahit_assemblies"
BAM_DIR="/home/marcos/PRJEB59406/ordened_bams"
OUTPUT_DIR="/home/marcos/PRJEB59406/MetaBAT2_bins"
RUNMETABAT="/home/marcos/PRJEB59406/MetaBAT2_bins/runMetaBat.sh"

mkdir -p "$OUTPUT_DIR"

#Loop through samples, defining how to find each file acording to name
for SAMPLE_DIR in "$MEGAHIT_DIR"/*; do
    SAMPLE_NAME=$(basename "$SAMPLE_DIR")
    CONTIGS_FILE="$SAMPLE_DIR/${SAMPLE_NAME}.final.contigs.fa"
    BAM_FILE="$BAM_DIR/${SAMPLE_NAME}_aligned_sorted.bam"

    if [[ -f "$CONTIGS_FILE" && -f "$BAM_FILE" ]]; then
        echo "Running MetaBAT for $SAMPLE_NAME"
        "$RUNMETABAT" -m 1500 "$CONTIGS_FILE" "$BAM_FILE" #(the default -m is 2500 and depending on the size of your contigs, many will be not computed for binning.)
    else
        echo "Missing files for $SAMPLE_NAME, skipping..."
    fi
done