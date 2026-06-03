#!/bin/bash

INPUT_DIR="/temporario2/17404478/PRJEB59406/assay_1/fastq_files"
OUTPUT_DIR="/temporario2/17404478/PRJEB59406/assay_1/concatenated_reads"
SAMPLE_MAP="/temporario2/17404478/PRJEB59406/sample_map.csv"

mkdir -p "$OUTPUT_DIR"

SAMPLES=$(tail -n +2 "$SAMPLE_MAP" | awk -F',' '{print $2}' | sort -u)

for SAMPLE in $SAMPLES; do

  ERRS=$(grep ",$SAMPLE," "$SAMPLE_MAP" | awk -F',' '{print $1}')
  ERR_COUNT=$(echo "$ERRS" | wc -w)

  R1_FILES=""
  R2_FILES=""

  for ERR in $ERRS; do
    R1="${INPUT_DIR}/${ERR}_1.fastq.gz"
    R2="${INPUT_DIR}/${ERR}_2.fastq.gz"

    [ -f "$R1" ] && R1_FILES="$R1_FILES $R1"
    [ -f "$R2" ] && R2_FILES="$R2_FILES $R2"
  done

  if [ -z "$R1_FILES" ]; then
    echo "[SKIP] $SAMPLE — anyone of the R1 files is missing, skipping"
    continue
  fi

  OUT_R1="${OUTPUT_DIR}/${SAMPLE}_1.fastq.gz"
  OUT_R2="${OUTPUT_DIR}/${SAMPLE}_2.fastq.gz"

  if [ "$ERR_COUNT" -eq 1 ]; then
   
    echo "[CP]   $SAMPLE — 1 ERR, copying"
    cp $R1_FILES "$OUT_R1"
    [ -n "$R2_FILES" ] && cp $R2_FILES "$OUT_R2"
  else

    echo "[CAT]  $SAMPLE — ${ERR_COUNT} ERRs, concatenating"
    cat $R1_FILES > "$OUT_R1"
    [ -n "$R2_FILES" ] && cat $R2_FILES > "$OUT_R2"
  fi

  echo "       ERRs: $ERRS"
  echo "       Out: $OUT_R1"

done
