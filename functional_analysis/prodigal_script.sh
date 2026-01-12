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
    
    [ -e "$CONTIGS_PATH" ] || continue # Skip if no matching files

    SAMPLE=$(basename "$CONTIGS_PATH") # Extract sample name from directory
    
    CONTIGS_FILE="$CONTIGS_PATH/final.contigs.fa" # Path to contigs file

    if [ ! -f "$CONTIGS_FILE" ]; then # Check if contigs file exists
        echo "WARNING: contings archive not found for $SAMPLE ($CONTIGS_FILE)" # Print warning message
        continue
    fi
# Run Prodigal
    echo "Running Prodigal for $SAMPLE"

    prodigal -i "$CONTIGS_FILE" \
             -o "$OUTPUT_DIR/${SAMPLE}.gff" \
             -a "$OUTPUT_DIR/${SAMPLE}.faa" \
             -d "$OUTPUT_DIR/${SAMPLE}.fna" \
             -p meta
# i: input file
# o: output file for genes in GFF format
# a: output file for protein translations
# d: output file for nucleotide sequences of genes
# p: mode (meta for metagenomic data)

    if [[ $? -eq 0 ]]; then
        echo "Prodigal completed for $SAMPLE."
    else
        echo "Error running Prodigal for $SAMPLE."
    fi
done

echo "Prodigal finished!"