#!/bin/bash

TARGET_DIR="/temporario2/17404478/PRJEB59406/assay_1/fastq_files"
URL_FILE="/temporario2/17404478/PRJEB59406/get_ena_PRJEB59406.sh" 

mkdir -p "$TARGET_DIR"
cd "$TARGET_DIR"
bash "$URL_FILE"

echo "Files downloaded: $(ls *.fastq.gz 2>/dev/null | wc -l)"