#!/bin/bash
eval "$(conda shell.bash hook)"
conda activate seqkit 

ASSEMBLY_DIR="/temporario2/17404478/PRJNA46333/assay/megahit_assemblies"

OUTPUT="assembly_stats.tsv"

echo "Generating assembly statistics with SeqKit..."

seqkit stats \
-T \
$ASSEMBLY_DIR/SRR*/final.contigs.fa \
> "$OUTPUT"

echo "Done."
echo "Output: $OUTPUT"
