#!/bin/bash

# --- CONFIGURATION ---
TARGET_DIR="/temporario2/17404478/PRJEB59406/filas_processamento/fila_/fastq_files"

echo "Creating directory: $TARGET_DIR"
mkdir -p "$TARGET_DIR"

URLS=(
    # Insert your URLs here
)

# --- DOWNLOAD PROCESS ---
echo "Starting downloads into fila..."

for url in "${URLS[@]}"; do
    echo "Downloading: $(basename "$url")"
    wget -nc -P "$TARGET_DIR" "$url"
done

echo "Downloads completed!"