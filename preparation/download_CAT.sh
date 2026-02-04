#!/bin/bash

BASE_DIR="/temporario2/17404478/PRJEB59406/code/data_base/CAT_data"
mkdir -p "$BASE_DIR"

cd "$BASE_DIR"

FILE_URL="tbb.bio.uu.nl/tina/CAT_pack_prepare/20241212_CAT_nr.tar.gz"
FILE_NAME="20241212_CAT_nr.tar.gz"

if [ -f "$FILE_NAME" ]; then
    echo "File $FILE_NAME found. Skipping download."
else
    echo "Download $FILE_NAME..."
    wget --no-check-certificate "$FILE_URL"
fi

tar -xvzf "$FILE_NAME"

if [ $? -eq 0 ]; then
    rm "$FILE_NAME"
else
    echo "Error during the decompression process."
    exit 1
fi

echo "Finish: $(date)"
ls -lh "$BASE_DIR"
