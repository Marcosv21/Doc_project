#!/bin/bash
# Dependencies: Fastp, Seqkit (optional for quality check)
# Install: conda install -c bioconda fastp seqkit

# Script for filtering using Fastp
# NOTE: Always check for errors in case of corrupted FastQ files
# If you encounter issues with a sample, check the quality using Seqkit
# Example: seqkit stats ERR9578161.fastq.gz
#Activate the Conda environment -- if need be
eval "$(conda shell.bash hook)"
conda activate fastp

# Directory containing the files
INPUT_DIR="/home/marcos/PRJEB59406/fastq_files"
OUTPUT_DIR="/media/marcos/TRABALHO/PRJEB59406/fastp_filtered"

# Create output directory if it does not exist
mkdir -p "$OUTPUT_DIR"

# Loop through _1.fastq.gz files
for FILE1 in "$INPUT_DIR"/*_1.fastq.gz; do
    # Extract the sample base name (removes the "_1.fastq.gz" suffix)
    BASENAME=$(basename "$FILE1" "_1.fastq.gz")

    # Define the second pair file
    FILE2="${INPUT_DIR}/${BASENAME}_2.fastq.gz"

    # Define output files
    OUTPUT1="${OUTPUT_DIR}/${BASENAME}_filtered_1.fastq.gz"
    OUTPUT2="${OUTPUT_DIR}/${BASENAME}_filtered_2.fastq.gz"

    # Run Fastp for the paired-end files
    echo "Processing $BASENAME..."
    fastp -i "$FILE1" -I "$FILE2" -o "$OUTPUT1" -O "$OUTPUT2" --detect_adapter_for_pe 
    # (Not strictly necessary; the default method removes adapters by comparing forward and reverse sequences.
    # A comparison between both methods showed only a 0.01% increase in removal using detect adapter 
    # on already pre-cleaned sequences.)

    # Check if the command was successful
    if [ $? -ne 0 ]; then
        echo "Error processing $BASENAME!" >&2
        exit 1
    fi
done
