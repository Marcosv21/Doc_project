#!/bin/bash
# Dependencies:Bowtie2
# Install:
#   conda install -c bioconda bowtie2

# Activate the Conda environment -- if need be
eval "$(conda shell.bash hook)"
conda activate bowtie2

# Define paths
FASTQ_PATH="/home/marcos/PRJEB59406/cleaned_reads"
INDEX_PATH="/home/marcos/PRJEB59406/indexed_fna"
OUTPUT_PATH="/home/marcos/PRJEB59406/fna_reads_aligned"

# Create the output directory if it doesn't exist
mkdir -p $OUTPUT_PATH

# Loop through all *_1.fastq files in the FASTQ_PATH
for FILE1 in "$FASTQ_PATH"/*_filtered_aligned_R1.fastq; do
 BASENAME=$(basename "$FILE1" "_filtered_aligned_R1.fastq")

  # Define the corresponding file for the _2.fastq.gz pair
  FILE2="${FASTQ_PATH}/${BASENAME}_filtered_aligned_R2.fastq"
  INDEX_FILE="${INDEX_PATH}/${BASENAME}_filtered_fna_indexed"

 # Check if both read files exist
  if [[ -f "$FILE1" && -f "$FILE2" ]]; then
    echo "Processing sample: $BASENAME"
    bowtie2 -x "$INDEX_FILE" \
      -1 "$FILE1" \
      -2 "$FILE2" \
      --threads 8 \
      -S "$OUTPUT_PATH/${BASENAME}_aligned_fna.sam"
      # -x: path to the genome index
      # -1: input read1
      # -2: input read2
      # --threads: number of threads
      # -S: output SAM file
  else
    echo "Warning: Missing pair for $BASENAME. Skipping alignment."
  fi
done

#    bowtie2 -x "$INDEX_FILE" \ # Define the indexed reference genome
#      -1 "$FILE1" \ # Define the first read file
#      -2 "$FILE2" \ # Define the second read file
#      --threads 8 \ # Use 8 threads for alignment
#      -S "$OUTPUT_PATH/${BASENAME}_aligned_fna.sam" # Define the output SAM file
#  else
#    echo "Warning: Missing pair for $BASENAME. Skipping alignment."
