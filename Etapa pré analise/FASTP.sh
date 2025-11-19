%%bash

# 1. Start Conda environment
set -e
eval "$(conda shell.bash hook)"

# 2. Checks if the 'fastp_env' environment 
if conda info --envs | grep -q "^fastp_env"; then
    echo "Env 'fastp_env' already exists."
else
    echo "env create 'fastp_env'..."
    # create an env quietly (-y)
    conda create -y -n fastp_env -c bioconda fastp seqkit
fi

# 3. Activate environment
echo "activate env fastp_env..."
conda activate fastp_env

# 4. define input and output directories
INPUT_DIR="/home/marcos/PRJEB59406/fastq_files"
OUTPUT_DIR="/home/marcos/PRJEB59406/fastp_files"

# create output directory if it doesn't exist
mkdir -p "$OUTPUT_DIR"

# 5. Count input files
count=$(ls "$INPUT_DIR"/*_1.fastq.gz 2>/dev/null | wc -l)

if [ "$count" -eq 0 ]; then
    echo "ERROR: No file *_1.fastq.gz in: $INPUT_DIR"
    echo "Check if the path is correct and if previous downloads worked."
    exit 1
fi

echo "$count files found. Starting processing..."

# 6. Loop process 
for FILE1 in "$INPUT_DIR"/*_1.fastq.gz; do
    
    BASENAME=$(basename "$FILE1" "_1.fastq.gz")
    FILE2="${INPUT_DIR}/${BASENAME}_2.fastq.gz"
    
    OUTPUT1="${OUTPUT_DIR}/${BASENAME}_filtered_1.fastq.gz"
    OUTPUT2="${OUTPUT_DIR}/${BASENAME}_filtered_2.fastq.gz"
    HTML_RPT="${OUTPUT_DIR}/${BASENAME}_report.html" 
    JSON_RPT="${OUTPUT_DIR}/${BASENAME}_report.json"

    
    if [ ! -f "$FILE2" ]; then
        echo "Par R2 não encontrado para $BASENAME. Pulando."
        continue
    fi

    echo "--------------------------------------------------"
    echo "Processing: $BASENAME"
    
    # Executa o fastp
    # Add --thread (nucleus use) Change as needed and possible in your system
    fastp -i "$FILE1" -I "$FILE2" \
          -o "$OUTPUT1" -O "$OUTPUT2" \
          -h "$HTML_RPT" -j "$JSON_RPT" \
          --detect_adapter_for_pe \
          --thread 8

    # Checks for errors in fastp execution
    if [ $? -ne 0 ]; then
        echo "ERROR in process $BASENAME"
        exit 1
    fi
done

echo "--------------------------------------------------"
echo "Processing completed!"
