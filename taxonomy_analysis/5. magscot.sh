#!/bin/bash

#If you need to install MAGScoT, you can do it with:
# conda create -n magscott_env -c conda-forge -c bioconda r-base r-dplyr r-tidyr r-magrittr r-getopt perl -y
# conda activate magscott_env
# cd /temporario2/17404478/code/taxonomy_functions/
# git clone https://github.com/ikmb/MAGScoT.git
# cd MAGScoT
# chmod +x MAGScoT.R
# conda install -c conda-forge r-optparse -y
# Rscript MAGScoT.R --help

eval "$(conda shell.bash hook)"
conda activate magscott_env

# =========================
# PATHS
# =========================
# For PRJNA46333:
BASE="/temporario2/17404478/PRJNA46333"
ASSEMBLY_DIR="$BASE/assay"
WORKDIR="$BASE/magscot"
# For PRJEB59406:
# BASE="/temporario2/17404478/PRJEB59406"
# ASSEMBLY_DIR="$BASE/filas_processamento"
# WORKDIR="$BASE/magscot"
# For PRJNA489681:
#BASE="/temporario2/17404478/PRJNA489681"
#ASSEMBLY_DIR="$BASE/filas_processamento"
#WORKDIR="$BASE/magscot"
MAGSCOT_SCRIPT="/temporario2/17404478/code/taxonomy_functions/MAGScoT/MAGScoT.R"
HMM_SOURCE="/temporario2/17404478/code/taxonomy_functions/MAGScoT/hmm"

mkdir -p "$WORKDIR"
CONCAT_FASTA="$WORKDIR/all_contigs.fa"
# =========================================================
# STEP 0 — CHECK DEPENDENCIES
# =========================================================
echo "Checking R packages..."
Rscript -e "libs<-c('digest','funr','optparse','dplyr','tidyr','readr'); lapply(libs, function(x) if(!require(x,character.only=T)) stop(paste('Falta o pacote:',x)))"

# =========================
# STEP 1 — CONCATENATE
# =========================
echo "Concating contigs from all samples..."
# For PRJNA46333:
> "$CONCAT_FASTA"
for f in $ASSEMBLY_DIR/megahit_assemblies/SRR*/final.contigs.fa; do

    sample=$(basename "$(dirname "$f")")

    echo "Processing $sample"

    awk -v s="$sample" '
    /^>/ {
        print ">" s "_" substr($0,2)
        next
    }
    {
        print
    }
    ' "$f" | \
    seqkit seq -m 2500 \
    >> "$CONCAT_FASTA"

done
# For PRJEB59406:
# cat $ASSEMBLY_DIR/fila_*/megahit_assemblies/ERR*/final.contigs.fa > "$CONCAT_FASTA"
# For PRJNA489681:  
#cat $ASSEMBLY_DIR/fila_0*/megahit_assemblies/SRR*/final.contigs.fa > "$CONCAT_FASTA"
echo "Preparing GTDB HMM markers..."
# The MAGScoT requires the HMMs of the GTDB. You can get them from the GTDB website, 
# but I already have them in a common path in the cluster. 
# If you want to use them, just concatenate the Pfam and TIGRFAM files into one, like this:
echo "Preparing GTDB HMM markers (Cleaning with hmmconvert)..."
# Usando hmmconvert para garantir que o formato esteja perfeito para o HMMER 3.4
hmmconvert "$HMM_SOURCE/gtdbtk_rel207_Pfam-A.hmm" > "$WORKDIR/Pfam_clean.hmm"
hmmconvert "$HMM_SOURCE/gtdbtk_rel207_tigrfam.hmm" > "$WORKDIR/Tigrfam_clean.hmm"
cat "$WORKDIR/Pfam_clean.hmm" "$WORKDIR/Tigrfam_clean.hmm" > "$WORKDIR/bac120_markers.hmm"


hmmstat "$WORKDIR/bac120_markers.hmm" | tail -n 5

# =========================
# STEP 2 — PRODIGAL (Protein prediction)
# =========================
echo "Running prodigal..."
prodigal -i "$CONCAT_FASTA" -a "$WORKDIR/proteins.faa" -p meta > /dev/null


# =========================
# STEP 3 — HMMER (GTDB markers)
# =========================
echo "Running hmmsearch..."
hmmsearch --tblout "$WORKDIR/markers.tsv" --cut_ga --cpu 12 \
    "$WORKDIR/bac120_markers.hmm" "$WORKDIR/proteins.faa"

# Formatação para o MAGScoT
awk '!/^#/ {print $1"\t"$3"\t"$13}' "$WORKDIR/markers.tsv" > "$WORKDIR/magscot_hmm.tsv"

# =========================
# STEP 4 — Mapping bin-contig
# =========================
echo "Building bin-contig mapping for MetaBAT2 and SemiBin2..."
MAP_FILE="$WORKDIR/bin_mapping.tsv"
> "$MAP_FILE"

echo "   -> Colecting bins do MetaBAT2..."
# For PRJNA46333:
for f in $BASE/assay/MetaBAT2_bins/SRR*/final.contigs.fa.metabat-bins*/*.fa; do
# For PRJEB59406:
# for f in $BASE/filas_processamento/fila_*/MetaBAT2_bins/ERR*/final.contigs.fa.metabat-bins*/*.fa; do
# For PRJNA489681:
# for f in $BASE/filas_processamento/fila_*/MetaBAT2_bins/SRR*/final.contigs.fa.metabat-bins*/*.fa; do
    if [ -f "$f" ]; then
        bin_name=$(basename "$f" .fa)
        
        sample_dir=$(dirname $(dirname "$f"))
        sample=$(basename "$sample_dir")
        
        grep "^>" "$f" | sed 's/^>//' | \
        awk -v s="$sample" -v b="$bin_name" \
        '{print s"_"b"\t"s"_"$1"\tmetabat2"}' \
        >> "$MAP_FILE"
    fi
done

echo "   -> Colecting bins do SemiBin2..."
# For PRJNA46333:
for d in $BASE/assay/semibin2/final_bins/SRR*; do
    sample=$(basename "$d")
    if [ -f "$d/contig_bins.tsv" ]; then
        awk -v s="$sample" \
        '{print s"_sb2_"$2"\t"s"_"$1"\tsemibin2"}' \
        "$d/contig_bins.tsv" >> "$MAP_FILE"
    fi
done
# For PRJEB59406 and PRJNA489681: (Switched SRR* for ERR* in PRJEB59406, but kept SRR* for PRJNA489681)
#for d in $BASE/filas_processamento/semibin2_2/final_bins/SRR*; do
#    sample=$(basename "$d")
#    if [ -f "$d/contig_bins.tsv" ]; then
#        awk -v s="$sample" '{print s"_sb2_"$2"\t"$1"\tsemibin2"}' "$d/contig_bins.tsv" >> "$MAP_FILE"
#    fi
# done

# =========================
# STEP 5 — MAGSCOT (quality scoring)
# =========================
echo "Running MAGScoT..."

Rscript "$MAGSCOT_SCRIPT" \
    -i "$WORKDIR/bin_mapping.tsv" \
    --hmm "$WORKDIR/magscot_hmm.tsv" \
    -p bac120 \
    -o "$WORKDIR/MAGScoT_Final_Atopica" \
    -t 0.5 \
    --max_cont 0.15 
# -i: input file with bin-contig mapping and source (MetaBAT2 or SemiBin2)
# --hmm: output from hmmsearch with GTDB markers
# -p: marker set to use (bac120 for bacteria)
# -o: output prefix for MAGScoT results
# -t 0.2: minimum completeness threshold (default 0.5)
# --max_cont 0.6: maximum contamination threshold (default 0.1)
# The mannual tools: https://github.com/ikmb/MAGScoT
echo "Done."