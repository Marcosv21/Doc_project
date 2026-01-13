#Don't forget to download the archive from ENA's site (script downloads wget)

#!/bin/bash

FASTQ_DIR="/media/marcos/TRABALHO/PRJEB59406/fastq_files"
URL_LIST="/home/marcos/PRJEB59406/enasdownload(1).sh"

mkdir -p "$FASTQ_DIR"

# Check if URL list file exists
if [ ! -f "$URL_LIST" ]; then
    echo "ERROR: List file $URL_LIST not found."
    exit 1
fi
echo "Starting file download to: $FASTQ_DIR" # Navigate to the target directory
cd "$FASTQ_DIR" || exit
while read -r LINE; do
    if [[ -z "$LINE" || "$LINE" == \#* ]]; then
        continue
    fi
    URL=$(echo "$LINE" | awk '{print $NF}')

    echo "------------------------------------------------"
    echo "Processing: $URL"
  
    wget -nc -c --show-progress "$URL" # Download the file with resume capability
    if [ $? -ne 0 ]; then
        echo "ERROR downloading: $URL"
    else
        echo "Success."
    fi
done < "$URL_LIST"
echo "------------------------------------------------"
echo "All downloads have been processed!"
