#!/bin/bash
# Dependencies: FLASH
# Install:
#   conda install -c bioconda flash
eval "$(conda shell.bash hook)"

# 2. Checks if the 'flash' environment 
if conda info --envs | grep -q "^flash"; then
    echo "Env 'flash' already exists."
else
    echo "env create 'megahit'..."
    conda create -y -n flash
    conda install -c flash
fi

# Activate the Conda environment -- if need be
conda activate flash

FASTQ_PATH = "/media/marcos/TRABALHO/PRJEB59406/fastp_filtered" #Pathway of the archive filtered (fastp)
OUTPUT_PATH_BASE = "/media/marcos/TRABALHO/PRJEB59406/flash_merged" 

mkdir -p "$OUTPUT_PATH"

# Loop through all *_R1.fastq files in the FASTQ_PATH
for FILE1 in "$FASTQ_PATH"/*_R1.fastq; do
  # Get the base name of the sample (remove the _R1.fastq suffix)
  BASENAME=$(basename "$FILE1" _R1.fastq)

  # Define the corresponding file for the _R2.fastq pair
  FILE2="${FASTQ_PATH}/${BASENAME}_R2.fastq"

  # Check if the _R2.fastq file exists
  if [ -f "$FILE2" ]; then
    # Merging with FLASH
    flash -m 20 -M 150 --to-stdout "$FILE1" "$FILE2" > "${OUTPUT_PATH}/${BASENAME}.merged.fastq" 
    # -m 20: based on the minimum merge of fastp, which is 30, and the default of FLASH, which is 10.
    # -M 150: avoids the WARNING from FLASH saying that many sequences overlap more than the parameter, but it didn't change the merge percentage
  else
    echo "Pair for file $FILE1 not found: $FILE2" >&2
  fi
done
