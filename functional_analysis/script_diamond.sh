#!/bin/bash
# Dependencies: Diamond
# Install:
# conda install bioconda::diamond

eval "$(conda shell.bash hook)"
conda activate diamond
# Define working directory
dir="/home/marcos/PRJEB59406/prodigal_outputs"
#define output directory
out_dir="/home/marcos/PRJEB59406/diamond_results"
mkdir -p "$out_dir"
# Define Diamond database path
db="/home/marcos/PRJEB59406/all_sequences.dmnd"  # DIAMOND database

# Loop to process all .faa files in the directory
for query in $dir/*.faa; do
    filename=$(basename "$query" .faa)
    output="${out_dir}/${filename}_matches.tsv"  # Output file name
    echo "Running DIAMOND for $query..."
    diamond blastp -d "$db" -q "$query" -o "$output" --outfmt 6 qseqid sseqid pident length qlen slen mismatch gapopen evalue bitscore
done

echo "Finished!"