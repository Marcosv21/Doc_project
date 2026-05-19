#!/bin/bash
#Dependencies: fastp
#Install:
#  conda install -c bioconda fastp

eval "$(conda shell.bash hook)"
conda activate FASTP

# Define paths
INPUT_DIR="/temporario2/17404478/PRJEB59406/filas_processamento/fila_1/fastq_files"
OUTPUT_DIR="/temporario2/17404478/PRJEB59406/filas_processamento/fila_1/fastp_filtered"
REPORT_DIR="/temporario2/17404478/PRJEB59406/fastp_quality"

# Create output directories if they do not exist
mkdir -p "$OUTPUT_DIR"
mkdir -p "$REPORT_DIR"

FAILED_LOG="${OUTPUT_DIR}/fastp_failed.txt"
# Clear previous failed log if exists
> "$FAILED_LOG"

# Process each pair of FASTQ files
for FILE1 in "$INPUT_DIR"/*_1.fastq.gz; do
    BASENAME=$(basename "$FILE1" "_1.fastq.gz")
    FILE2="${INPUT_DIR}/${BASENAME}_2.fastq.gz"

# Define output files
    OUTPUT1="${OUTPUT_DIR}/${BASENAME}_filtered_1.fastq.gz"
    OUTPUT2="${OUTPUT_DIR}/${BASENAME}_filtered_2.fastq.gz"
    HTML_REPORT="${REPORT_DIR}/${BASENAME}_fastp.html"
    JSON_REPORT="${REPORT_DIR}/${BASENAME}_fastp.json"
# Check if the corresponding _2 file exists 
    if [[ ! -f "$FILE2" ]]; then
        echo "Warning: Corresponding file $FILE2 not found. Skipping $BASENAME." | tee -a "$FAILED_LOG"
        continue
    fi

    if ! gzip -t "$FILE1" 2>/dev/null; then
        echo "Warning: File $FILE1 is not a valid gzip file. Skipping $BASENAME." | tee -a "$FAILED_LOG"
        continue
    fi
    if ! gzip -t "$FILE2" 2>/dev/null; then
        echo "Warning: File $FILE2 is not a valid gzip file. Skipping $BASENAME." | tee -a "$FAILED_LOG"
        continue
    fi

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
        echo "Error processing $BASENAME!" | tee -a "$FAILED_LOG"
        continue
    fi
done

echo "Processing complete! Reports saved in: $REPORT_DIR"

FAIL_COUNT=$(wc -l < "$FAILED_LOG")
if [ "$FAIL_COUNT" -gt 0 ]; then
    echo "Some files were skipped due to errors. See $FAILED_LOG for details."
else
    cat "$FAILED_LOG"
fi