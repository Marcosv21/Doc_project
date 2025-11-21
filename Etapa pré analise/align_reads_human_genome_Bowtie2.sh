#!/bin/bash
# Dependencies: Bowtie2
# Install:
#wget https://sourceforge.net/projects/bowtie-bio/files/bowtie2/2.5.4/bowtie2-2.5.4-linux-x86_64.zip/download
#conda install -c bioconda bowtie2

# Activate the Conda environment -- if need be
eval "$(conda shell.bash hook)"
conda activate Bowtie2

# Define paths
FASTQ_PATH="/home/marcos/Teste/FASTP"
OUTPUT_PATH="/home/marcos/Teste/Bowtie2/output"
GENOME_INDEX_PATH="/home/marcos/Teste/Bowtie2"
GENOME_FASTA="${GENOME_INDEX_PATH}/GCF_000001405.40_GRCh38.p14_genomic.fna"
INDEX_BASE="${GENOME_INDEX_PATH}/GRCh38_index"

# Create the output directory if it doesn't exist
mkdir -p $OUTPUT_PATH

#Verification construction 

if [ ! -f "${GENOME_FASTA}" ]; then
    echo "(ERROR): FASTA reference archive '${GENOME_FASTA}' not found."
    echo "Check the pathway."
    exit 1
fi

# Check if index (arquivo .1.bt2) exists
if [ ! -f "${INDEX_BASE}.1.bt2" ]; then
    echo "Index Bowtie 2 not found. Building index..."
    bowtie2-build "${GENOME_FASTA}" "${INDEX_BASE}"
    if [ $? -eq 0 ]; then
        echo "Index successfully built: ${INDEX_BASE}"
    else
        echo "(ERROR): Fail building index."
        exit 1
    fi
else
    echo "Index Bowtie2 (${INDEX_BASE}) exists yet."
fi

# Loop through all *_1.fastq.gz files in the FASTQ_PATH
for FILE1 in $FASTQ_PATH/*_1.fastq.gz; do
  # Get the base name of the sample (without the _1.fastq.gz suffix)
  BASENAME=$(basename $FILE1 _1.fastq.gz)
  
  # Define the corresponding file for the _2.fastq.gz pair
  FILE2="${FASTQ_PATH}/${BASENAME}_2.fastq.gz"

  echo "Alinhando a amostra: ${BASENAME}"

  # Alignment with Bowtie2
  bowtie2 -x $INDEX_BASE \
    -1 $FILE1 \
    -2 $FILE2 \
    --threads 8 \
    --very-sensitive-local #Deixará muito mais sensivel no alinhamento, irá demorar mais
    -S $OUTPUT_PATH/${BASENAME}_aligned.sam

done

# NOTE: Bowtie2 generates a single output file containing the alignment of both sequences (forward and reverse).
