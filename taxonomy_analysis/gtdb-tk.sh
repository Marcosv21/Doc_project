#!/bin/bash
# Dependencies: GTDB-Tk
# Installation: conda install -c conda-forge -c bioconda gtdbtk

eval "$(conda shell.bash hook)"
conda activate gtdbtk

# CONFIGURATION
SOURCE_BINS_DIR="/home/marcos/PRJEB59406/MetaBAT2_bins"
INPUT_DIR="/home/marcos/PRJEB59406/gtdb_input_all_bins"
OUTPUT_DIR="/home/marcos/PRJEB59406/taxonomy_gtdb"

# Database path
export GTDBTK_DATA_PATH="/home/marcos/miniconda3/envs/gtdbtk/share/gtdbtk-2.6.1/db"

# STEP 1: PREPARE INPUT
echo "1. Organizing input files..."
mkdir -p "$INPUT_DIR"
mkdir -p "$OUTPUT_DIR"

# Symlink all .fa files to the input directory
find "$SOURCE_BINS_DIR" -name "*.fa" -exec ln -sf {} "$INPUT_DIR" \;

# Validate file count
NUM_GENOMES=$(ls "$INPUT_DIR"/*.fa | wc -l)
echo "Genomes found: $NUM_GENOMES"

if [ "$NUM_GENOMES" -eq 0 ]; then 
    echo "ERROR: No .fa files found in $SOURCE_BINS_DIR"
    exit 1
fi

# STEP 2: RUN GTDB-TK
echo "2. Running GTDB-Tk classification..."

# Memory optimization: pplacer_cpus=1 and skip_ani_screen to reduce RAM usage
# Run the classification workflow
gtdbtk classify_wf \
    --genome_dir "$INPUT_DIR" \
    --extension 'fa' \
    --out_dir "$OUTPUT_DIR" \
    --cpus 8 \
    --pplacer_cpus 1 \
    --skip_ani_screen
# genome_dir: Directory with input genomes
# extension: File extension of genome files
# out_dir: Output directory
# cpus: Number of CPUs to use
# pplacer_cpus: Number of CPUs for pplacer (set to 1 for lower RAM usage)
# skip_ani_screen: Skip ANI screening to save memory    
echo "------------------------------------------------"
echo "Done. Results: $OUTPUT_DIR"