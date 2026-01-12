#!/bin/bash
# Dependencies: Bowtie2
# Install:
#   conda install -c bioconda bowtie2

#Activate the Conda environment (if needed)
eval "$(conda shell.bash hook)"
conda activate Bowtie2

# Directories
MEGAHIT_DIR="/temporario2/17404478/PRJEB59406/filas_processamento/fila_1/megahit_assemblies"
OUTPUT_DIR="/temporario2/17404478/PRJEB59406/filas_processamento/fila_1/indexed_contigs"

# Create the output directory if it doesn't exist
mkdir -p "$OUTPUT_DIR"

# Loop through the samples
for CONTIGS_PATH in "$MEGAHIT_DIR"/ERR*; do
    # Get the sample name from the folder name
    SAMPLE=$(basename "$CONTIGS_PATH")
    CONTIGS_FILE="$CONTIGS_PATH/final.contigs.fa"

    # Check if the contigs file exists
    if [[ -f "$CONTIGS_FILE" ]]; then
        echo "Indexing $SAMPLE..."

        # Index the contigs
        bowtie2-build "$CONTIGS_FILE" "$OUTPUT_DIR/${SAMPLE}_indexed"

        # Check if the command was successful
        if [[ $? -eq 0 ]]; then
            echo "Indexing completed for $SAMPLE."
        else
            echo "Error indexing $SAMPLE."
        fi
    else
        echo "Contigs file not found for $SAMPLE, skipping..."
    fi
done