#!/bin/bash

PROCESS_DIR="/temporario2/17404478/PRJEB59406/filas_processamento"

for i in {1..4}; do
    TARGET_PATH="${PROCESS_DIR}/fila_${i}/fastq_files"
    echo "Creating: $TARGET_PATH"
    mkdir -p "$TARGET_PATH"
done

URLS=(
)

declare -A sample_map

current_queue=1

echo "Starting download and distribution..."

for url in "${URLS[@]}"; do
    filename=$(basename "$url")
    
    sample_id=$(echo "$filename" | cut -d'_' -f1)
    if [[-v sample_map[$sample_id] ]]; then
       queue_num=${sample_map[$sample_id]}
    else
       queue_num=$current_queue
       sample_map[$sample_id]=$queue_num

       current_queue=$((current_queue + 1))
       if [ $current_queue -gt 4 ]; then
          current_queue=1
       fi
    fi
    
    target_dir="${PROCESS_DIR}/fila_${queue_num}/fastq_files"
    wget -nc -P "$target_dir" "$url"
done
