#!/bin/bash
# Dependencies: Bowtie2
# Install:
#   conda install -c bioconda bowtie2

#Activate the Conda environment (if needed)
eval "$(conda shell.bash hook)"
conda activate Bowtie2

# Directories
PRODIGAL_DIR="/home/marcos/PRJNA489681/ORGANIZED_RESULTS_PRJNA489681/functional/filtered_fnaw"
OUTPUT_DIR="/home/marcos/PRJNA489681/ORGANIZED_RESULTS_PRJNA489681/functional/indexed_fnaw"

# Create the output directory if it doesn't exist
mkdir -p "$OUTPUT_DIR"

# Loop through the samples
for FNA_FILE in "$PRODIGAL_DIR"/*.fna; do
        SAMPLE=$(basename "$FNA_FILE" .fna)

        # Index the contigs file using Bowtie2 
        bowtie2-build "$FNA_FILE" "$OUTPUT_DIR/${SAMPLE}_fna_indexed"
        
        # Check if the command was successful
        if [[ $? -eq 0 ]]; then
            echo "Indexing completed for $SAMPLE."
        else
            echo "Error indexing $SAMPLE."
        fi
   done