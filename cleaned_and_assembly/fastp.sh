#!/bin/bash
#Dependencies: fastp
#Install:
#  conda install -c bioconda fastp

eval "$(conda shell.bash hook)"
conda activate FASTP

# Define paths
INPUT_DIR="/home/marcos/PRJEB59406/fastq_files"
OUTPUT_DIR="/home/marcos/PRJEB59406/fastp_filtered"
REPORT_DIR="/home/marcos/PRJEB59406/fastp_quality"

# Create output directories if they do not exist
mkdir -p "$OUTPUT_DIR"
mkdir -p "$REPORT_DIR"

# Process each pair of FASTQ files
for FILE1 in "$INPUT_DIR"/*_1.fastq.gz; do
    BASENAME=$(basename "$FILE1" "_1.fastq.gz")
    FILE2="${INPUT_DIR}/${BASENAME}_2.fastq.gz"

# Define output files
    OUTPUT1="${OUTPUT_DIR}/${BASENAME}_filtered_1.fastq.gz"
    OUTPUT2="${OUTPUT_DIR}/${BASENAME}_filtered_2.fastq.gz"
    HTML_REPORT="${REPORT_DIR}/${BASENAME}_fastp.html"
    JSON_REPORT="${REPORT_DIR}/${BASENAME}_fastp.json"

    echo "Processing $BASENAME..."
    # Run fastp for paired-end data with adapter detection and quality filtering
    fastp -i "$FILE1" -I "$FILE2" \
          -o "$OUTPUT1" -O "$OUTPUT2" \
          --detect_adapter_for_pe \
          -h "$HTML_REPORT" \
          -j "$JSON_REPORT"

# -i: input read1
# -I: input read2
# -o: output read1
# -O: output read2
# --detect_adapter_for_pe: automatically detect adapters for paired-end data
# -h: HTML report
# -j: JSON report
# Check if fastp ran successfully 
    if [ $? -ne 0 ]; then
        echo "Error processing $BASENAME!" >&2
        exit 1
    fi
done

echo "Processing complete! Reports saved in: $REPORT_DIR"