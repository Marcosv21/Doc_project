#!/bin/bash
# Dependencies: samtools
# Install:
#   conda install -c bioconda samtools
eval "$(conda shell.bash hook)"
conda activate samtools

INPUT_DIR="/temporario2/17404478/PRJNA46333_2/assay/bowtie2_aligned"
OUTPUT_DIR="/temporario2/17404478/PRJNA46333_2/assay/cleaned_reads"
TEMP_DIR="$OUTPUT_DIR/tmp"

mkdir -p "$OUTPUT_DIR" "$TEMP_DIR"

for BAM_FILE in "$INPUT_DIR"/*_filtered.bam; do
  BASENAME=$(basename "$BAM_FILE" _filtered.bam)

  echo "Processing: $BASENAME"

  # Extract reads that did not align to the human genome
  samtools view -@ 8 -b -f 12 -F 256 "$BAM_FILE" > "$TEMP_DIR/${BASENAME}_both.bam"
  samtools view -@ 8 -b -f 4  -F 264 "$BAM_FILE" > "$TEMP_DIR/${BASENAME}_r1.bam"
  samtools view -@ 8 -b -f 8  -F 260 "$BAM_FILE" > "$TEMP_DIR/${BASENAME}_r2.bam"

  samtools merge -f -@ 8 "$TEMP_DIR/${BASENAME}_merged.bam" \
    "$TEMP_DIR/${BASENAME}_both.bam" \
    "$TEMP_DIR/${BASENAME}_r1.bam" \
    "$TEMP_DIR/${BASENAME}_r2.bam"

  # Ordened by name for paired-end conversion
  samtools sort -n -@ 8 "$TEMP_DIR/${BASENAME}_merged.bam" \
    -o "$TEMP_DIR/${BASENAME}_sorted.bam"

  # Convert to FASTQ, separating paired-end, singletons, and others
  samtools fastq -@ 8 \
    -1 "$OUTPUT_DIR/${BASENAME}_R1.fastq" \
    -2 "$OUTPUT_DIR/${BASENAME}_R2.fastq" \
    -s "$OUTPUT_DIR/${BASENAME}_singleton.fastq" \
    -0 "$OUTPUT_DIR/${BASENAME}_other.fastq" \
    -n \
    "$TEMP_DIR/${BASENAME}_sorted.bam"

  # Clean up temporary BAM files
  rm "$TEMP_DIR/${BASENAME}"_*.bam
  echo "Done: $BASENAME"
done

rm -rf "$TEMP_DIR"
echo "All samples processed!"