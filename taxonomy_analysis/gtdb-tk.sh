#!/bin/bash
# Dependências: GTDB-Tk
# Instalação: conda install -c conda-forge -c bioconda gtdbtk

eval "$(conda shell.bash hook)"
conda activate gtdbtk

GENOME_DIR=""/home/marcos/PRJEB59406/MetaBAT2_bins/checkm_results""
OUTPUT_DIR="/home/marcos/PRJEB59406/taxonomy_gtdb"

export GTDBTK_DATA_PATH="/home/marcos/PRJEB59406/Data_base/gtdbtk_r220_data"
mkdir -p "$OUTPUT_DIR"

gtdbtk classify_wf \
    --genome_dir "$GENOME_DIR" \
    --extension 'fa' \
    --out_dir "$OUTPUT_DIR" \
    --cpus 24 \
    --pplacer_cpus 1 \


echo "Finish! The pathway: $OUTPUT_DIR"