#!/bin/bash 

eval "$(conda shell.bash hook)"
conda activate seqkit 

BASE_DIR="/temporario2/17404478/PRJNA489681/filas_processamento"
BAM_DIR="$BASE_DIR/semibin2/realigned_bams"
OUTPUT_DIR="$BASE_DIR"
SAMPLE_MAP="/temporario2/17404478/PRJNA489681/sample_map.csv"

seqkit stats "$BASE_DIR"/fila_0*/cleaned_reads/*.fastq -T -j 12 > "$OUTPUT_DIR/reads_stats.tsv"

echo -e "run_accession\tmapped_reads" > "$OUTPUT_DIR/mapped_counts.tsv"

for bam in "$BAM_DIR"/*.sorted.bam; do
    if [ -f "$bam" ]; then
        sample=$(basename "$bam" | cut -d'_' -f1)
        count=$(samtools view -c -F 4 "$bam")
        echo -e "$sample\t$count" >> "$OUTPUT_DIR/mapped_counts.tsv"
    fi
done

# STEP PYTHON — MERGE AND CALCULATE PERCENTAGES

python3 <<EOF
import pandas as pd

stats_fastq = "$OUTPUT_DIR/reads_stats.tsv"
stats_mapped = "$OUTPUT_DIR/mapped_counts.tsv"
sample_map = "$SAMPLE_MAP"
output_csv = "$OUTPUT_DIR/planilha_final_reads.csv"

df_seqkit = pd.read_csv(stats_fastq, sep="\t")
df_seqkit['run_accession'] = df_seqkit['file'].apply(lambda x: x.split('/')[-1].split('_')[0])
df_reads = df_seqkit.groupby('run_accession').agg({'num_seqs': 'sum', 'avg_len': 'mean'}).reset_index()

df_mapped = pd.read_csv(stats_mapped, sep="\t")

df_groups = pd.read_csv(sample_map)

final = df_groups.merge(df_reads, on='run_accession', how='left')
final = final.merge(df_mapped, on='run_accession', how='left')

final['%_Aproveitamento'] = (final['mapped_reads'] / final['num_seqs']) * 100

final.columns = ['ID', 'Named', 'Group', 'Total_cleaned_reads', 'Mean_Read_Length', 'Reads_mapped_catalog', 'Perc_aprov']

final.to_csv(output_csv, index=False)
EOF
