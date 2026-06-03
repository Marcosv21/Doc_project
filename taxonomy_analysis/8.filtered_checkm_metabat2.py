import os
import pandas as pd
import shutil
import glob

CHECKM_DIR = "/temporario2/17404478/PRJNA46333_2/checkm_results_metabat2"
BINS_DIR = "/temporario2/17404478/PRJNA46333_2/assay/MetaBAT2_bins"
OUTPUT_DIR = "/temporario2/17404478/PRJNA46333_2/assay/filtered_bins_high_quality_metabat2"

MIN_COMP = 50.0
MAX_CONT = 10.0

os.makedirs(OUTPUT_DIR, exist_ok=True)

tables = glob.glob(f"{CHECKM_DIR}/*/quality_table.tsv")

total = 0

for table in tables:

    sample = table.split("/")[-2]

    df = pd.read_csv(table, sep="\t")

    good_bins = df[
        (df["Completeness"] >= MIN_COMP) &
        (df["Contamination"] <= MAX_CONT)
    ]

    # encontra pasta do metabat
    metabat_dirs = glob.glob(
        f"{BINS_DIR}/{sample}/final.contigs*.metabat-bins*"
    )

    if not metabat_dirs:
        print(f"No MetaBAT2 folder found for {sample}")
        continue

    bins_path = metabat_dirs[0]

    for bin_id in good_bins["Bin Id"]:

        bin_file = f"{bins_path}/{bin_id}.fa"

        if os.path.exists(bin_file):

            new_name = f"{sample}_{bin_id}.fa"

            shutil.copy2(
                bin_file,
                f"{OUTPUT_DIR}/{new_name}"
            )

            total += 1

            print(f"Copied: {new_name}")

        else:
            print(f"Not found: {bin_file}")

print(f"\nDONE! {total} bins copied.")