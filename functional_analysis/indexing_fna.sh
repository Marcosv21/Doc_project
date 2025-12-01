#!/bin/bash
# Dependencies: Bowtie2
# Install:
#   conda install -c bioconda bowtie2

#Activate the Conda environment (if needed)
eval "$(conda shell.bash hook)"
conda activate bowtie2

# Directories
PRODIGAL_DIR="/home/marcos/PRJEB59406/filtered_fna"
OUTPUT_DIR="/home/marcos/PRJEB59406/indexed_fna"

# Create the output directory if it doesn't exist
mkdir -p "$OUTPUT_DIR"

# Loop through the samples
for FNA_FILE in "$PRODIGAL_DIR"/*.fna; do
        SAMPLE=$(basename "$FNA_FILE" .fna)

        # Index the contigs
        bowtie2-build "$FNA_FILE" "$OUTPUT_DIR/${SAMPLE}_fna_indexed"

        # Check if the command was successful
        if [[ $? -eq 0 ]]; then
            echo "Indexing completed for $SAMPLE."
        else
            echo "Error indexing $SAMPLE."
        fi
   done