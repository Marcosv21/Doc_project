#!/bin/bash
# Dependencies: MEGAHIT
# Install:
#   conda install -c bioconda megahit
eval "$(conda shell.bash hook)"

# 3. Activate environment
echo "activate env megahit..."
conda activate megahit

FASTQ_PATH="/temporario2/17404478/PRJEB59406/cleaned_reads" 
MERGED_PATH="/temporario2/17404478/PRJEB59406//merged_reads" 
OUTPUT_PATH="/temporario2/17404478/PRJEB59406/megahit_assemblies"

mkdir -p "$OUTPUT_PATH"

#Loop to proccess all files in FASTQ_PATH
for FILE1 in "$FASTQ_PATH"/*_R1.fastq; do
  # Obtain the basename of the sample (remove sufix _filtered_aligned_R1. fastq)
  BASENAME=$(basename "$FILE1" _filtered_aligned_R1.fastq)

  # Define the pair file _filtered_aligned_R2.fastq
  FILE2="${FASTQ_PATH}/${BASENAME}_filtered_aligned_R2.fastq"
  
  #Define the merged file 
  FILE3="${MERGED_PATH}/${BASENAME}_filtered_aligned.merged.fastq"

  #Directory name
  DIR_NAME="${OUTPUT_PATH}/${BASENAME}"
  
  # Check if assembly already exists
  if [ -f "DIR_NAME/contigs.fa"]; then
    echo "Assembly already exists for $BASENAME, skipping..."
    continue
  fi

  # Check is the incomplete paste exists, remove and reassemble
  if [ -d "$DIR_NAME" ]; then
    echo "Incomplete assembly found for $BASENAME, removing and reassembling..."
    rm -rf "$DIR_NAME"
  fi
  #Assembling with MEGAHIT
  megahit -1 "$FILE1" -2 "$FILE2" -r "$FILE3" -o "$OUTPUT_PATH/${BASENAME}" -m 0.8 -t 20
done
