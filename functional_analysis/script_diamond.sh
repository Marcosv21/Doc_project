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
db="/home/marcos/PRJEB59406/data_base1/diamond_db/all_sequences.dmnd"  # DIAMOND database

# Loop to process all .faa files in the directory
for query in $dir/*.faa; do
    filename=$(basename "$query" .faa)
    output="${out_dir}/${filename}_matches.tsv"  # Output file name
    echo "Running DIAMOND for $query..."
    diamond blastp -d "$db" \
                   -q "$query" \
                   -o "$output" \
                   --more-sensitive \
                   --outfmt 6 qseqid sseqid pident length mismatch gapopen qstart qend sstart send evalue bitscore qlen slen \

done

echo "Finished!"
#  diamond blastp -d "$db" \ Define Diamond database path
#                   -q "$query" \ Define query file
#                   -o "$output" \ Define output file
#                   --mid-sensitive \ Use mid-sensitive mode (balances speed and sensitivity), 
#                     but can be adjusted based on needs, for example --sensitive for more sensitivity or --fast for speed or --more-sensitive for more sensitivity
#                   --outfmt 6 (Define format of the outpu, number 6 equal BLAST tabular format) qseqid sseqid pident 
#                     length mismatch gapopen qstart qend sstart send evalue bitscore qlen slen \ Define output format (tabular with specific fields)
