#!/bin/bash
# Dependencies: Samtools
# Install:
#   conda install -c bioconda samtools
# 1. Start Conda environment initialization

eval "$(conda shell.bash hook)"

# Activate environment
echo "Activating env samtools..."
conda activate samtools
# Define paths
INPUT_DIR="/home/marcos/PRJEB59406/bowtie2_aligned"
OUTPUT_DIR="/home/marcos/PRJEB59406/cleaned_reads"
# Create output directory if it does not exist
mkdir -p "$OUTPUT_DIR"
# Processing
for SAM_FILE in "$INPUT_DIR"/*.sam; do
  BASENAME=$(basename "$SAM_FILE" .sam)

  echo "Processing archive: ${BASENAME}.sam"
  
  # Convert and filter SAM -> BAM
  samtools view -@ 8 -b -f 12 -F 256 "$SAM_FILE" > "$OUTPUT_DIR/${BASENAME}_filtered.bam" 
  # @8: number of threads
  # -b: output in BAM format
  # -f 12: include reads with flags 4 (unmapped) and 8 (mate unmapped).
  # -F 256: exclude reads with flag 256 (not primary alignment).
  # Filter options: -f: Have a all flags present, -F : Anything flags present.

  # Convert BAM to FASTQ
  samtools fastq -@ 8 -1 "$OUTPUT_DIR/${BASENAME}_R1.fastq" -2 "$OUTPUT_DIR/${BASENAME}_R2.fastq" "$OUTPUT_DIR/${BASENAME}_filtered.bam"
  # -1: output read1
  # -2: output read2
  # -@ 8: number of threads
  
  echo " ${BASENAME}_R1.fastq and ${BASENAME}_R2.fastq creates."

  # Remove intermediate file (optional)
  rm "$OUTPUT_DIR/${BASENAME}_filtered.bam"
done

echo ""
echo "Finished processing all files!"
