import os
import pandas as pd
import shutil
import glob

CHECKM_DIR = "/temporario2/17404478/PRJNA46333_2/checkm_results_semibin2"
BINS_DIR = "/temporario2/17404478/PRJNA46333_2/assay/semibin2/final_bins"
OUTPUT_DIR = "/temporario2/17404478/PRJNA46333_2/assay/filtered_bins_high_quality_semibin2"

MIN_COMP = 50.0
MAX_CONT = 10.0

os.makedirs(OUTPUT_DIR, exist_ok=True)

tables = glob.glob(f"{CHECKM_DIR}/*/quality_table.tsv")

total = 0

for table in tables:

    # nome da amostra
    sample = table.split("/")[-2]

    # lê tabela do CheckM
    df = pd.read_csv(table, sep="\t")

    # filtra bins bons
    good_bins = df[
        (df["Completeness"] >= MIN_COMP) &
        (df["Contamination"] <= MAX_CONT)
    ]

    # pasta dos bins dessa amostra
    bins_path = f"{BINS_DIR}/{sample}/output_bins"

    for bin_id in good_bins["Bin Id"]:

        bin_file = f"{bins_path}/{bin_id}.fa"

        if os.path.exists(bin_file):

            # renomeia para não sobrescrever
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