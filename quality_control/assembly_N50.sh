#!/bin/bash

eval "$(conda shell.bash hook)"
conda activate seqkit 

ASSEMBLY_DIR="/temporario2/17404478/PRJNA46333/assay/megahit_assemblies"

OUTPUT="assembly_n50.tsv"

echo -e "Sample\tN50" > "$OUTPUT"

for f in $ASSEMBLY_DIR/SRR*/final.contigs.fa; do

    sample=$(basename "$(dirname "$f")")

    n50=$(seqkit fx2tab -nl "$f" | \
    cut -f2 | \
    sort -nr | \
    awk '
    {
        len[NR]=$1
        total+=$1
    }

    END{
        half=total/2

        for(i=1;i<=NR;i++){
            sum+=len[i]

            if(sum>=half){
                print len[i]
                exit
            }
        }
    }')

    echo -e "$sample\t$n50" >> "$OUTPUT"

done

echo "Done."
echo "Output: $OUTPUT"
