#!/bin/bash
# Dependencies: CD-HIT, DIAMOND

eval "$(conda shell.bash hook)"
conda activate cdhit

# --- CONFIGURATION ---
INPUT_DIR="/temporario2/17404478/PRJEB59406/code/data_base/pathway_db"
OUTPUT_DIR="/temporario2/17404478/PRJEB59406/code/data_base/pathway_db/db"
DB_NAME="sialic_acid_pathway"

mkdir -p "$OUTPUT_DIR"

# Loop through all fasta files
for FILE in "$INPUT_DIR"/*.fasta; do
    [ -e "$FILE" ] || continue

    FILENAME=$(basename "$FILE")
    
    # Identify Gene Tag from filename
    if   [[ "$FILENAME" == *"nanA"* ]]; then TAG="nanA"
    elif [[ "$FILENAME" == *"nanE"* ]]; then TAG="nanE"
    elif [[ "$FILENAME" == *"nanH"* ]]; then TAG="nanH"
    elif [[ "$FILENAME" == *"nanK"* ]]; then TAG="nanK"
    elif [[ "$FILENAME" == *"nanT"* ]]; then TAG="nanT"
    else TAG="Unknown"; fi

    echo "Processing: $TAG ($FILENAME)..."

    # 1. Clean Headers & Add Tag
    # - tr: removes Windows line breaks
    # - sed 1: Cleans UniProt (>sp|ID|... -> >ID)
    # - sed 2: Truncates descriptions (>ID description -> >ID)
    # - sed 3: Adds the tag (>ID -> >TAG|ID)
    cat "$FILE" | tr -d '\r' | \
    sed -E 's/^>(sp|tr)\|([A-Z0-9]+)\|.*/>\2/' | \
    sed -E 's/^>([^ ]+).*/\>\1/' | \
    sed "s/^>/>${TAG}|/" > "$OUTPUT_DIR/${TAG}.tmp"

    # 2. CD-HIT (Remove 100% duplicates)
    cd-hit -i "$OUTPUT_DIR/${TAG}.tmp" -o "$OUTPUT_DIR/${TAG}_nr.fasta" -c 1.0 -n 5 -M 16000 -d 0 -T 8 > /dev/null
    
    # Remove temp files
    rm "$OUTPUT_DIR/${TAG}.tmp" "$OUTPUT_DIR/${TAG}_nr.fasta.clstr"
done

# 3. Merge All Sequences
echo "Merging sequences..."
cat "$OUTPUT_DIR"/*_nr.fasta > "$OUTPUT_DIR/${DB_NAME}.fasta"

# 4. Create DIAMOND Database
echo "Building DIAMOND index..."
diamond makedb --in "$OUTPUT_DIR/${DB_NAME}.fasta" -d "$OUTPUT_DIR/${DB_NAME}" --quiet

# Optional: Cleanup intermediate files
rm "$OUTPUT_DIR"/*_nr.fasta

echo "Done! Database: $OUTPUT_DIR/${DB_NAME}.dmnd"