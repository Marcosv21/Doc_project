#!/bin/bash
# Dependencies: SRA Toolkit (prefetch, fastq-dump)
# Install: conda install -c bioconda sra-tools

eval "$(conda shell.bash hook)"
conda activate sra-tools

# Path to the file with accession numbers (a simple text file with one accession number per line) - it's acquired file in run selector (SRA)
ACCESSION_FILE="/temporario2/17404478/PRJNA46333/SRR_Acc_List.txt" 

# Destination directories
SRA_DIR="/temporario2/17404478/PRJNA46333/sra_files"
FASTQ_DIR="/temporario2/17404478/PRJNA46333/assay/fastq_files"

# Create directories if they do not exist
mkdir -p $SRA_DIR
mkdir -p $FASTQ_DIR

# Loop through each accession number in the file
while read ACCESSION; do
    echo "Downloading $ACCESSION..."

    # Download the .sra file
    prefetch --output-directory $SRA_DIR $ACCESSION

    if [ $? -eq 0 ]; then
        echo "$ACCESSION successfully downloaded. Converting to FASTQ..."

        # Path to the downloaded SRA file
        SRA_FILE="$SRA_DIR/$ACCESSION/$ACCESSION.sra"

        # Convert to FASTQ
        fastq-dump --split-3 --gzip -O $FASTQ_DIR $SRA_FILE

        if [ $? -eq 0 ]; then
            echo "$ACCESSION successfully converted to FASTQ!"
        else
            echo "Error converting $ACCESSION to FASTQ!"
        fi
    else
        echo "Error downloading $ACCESSION!"
    fi
done < "$ACCESSION_FILE"

echo "Process completed!"
