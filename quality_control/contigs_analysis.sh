#!/bin/bash

eval "$(conda shell.bash hook)"
conda activate seqkit 

ASSEMBLY_DIR="/temporario2/17404478/PRJNA46333/assay/megahit_assemblies"

OUTPUT="contigs_gt1kb.tsv"

echo -e "Sample\tContigs_gt_1kb" > "$OUTPUT"

for f in $ASSEMBLY_DIR/SRR*/final.contigs.fa; do

    sample=$(basename "$(dirname "$f")")

    count=$(seqkit seq -m 1000 "$f" | grep -c "^>")

    echo -e "$sample\t$count" >> "$OUTPUT"

done

echo "Done."
echo "Output: $OUTPUT"
