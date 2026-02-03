import pandas as pd
import os
import glob


RESULTS_DIR = "/temporario2/17404478/PRJEB59406/filas_processamento/fila_1/BAT_classification"
OUTPUT_FILE = "/temporario2/17404478/PRJEB59406/results/BAT_Final_Summary_All_Samples.tsv"

print(f"Searching for results in: {RESULTS_DIR}")

# Recursive search for all '_NAMES.txt' files
all_files = glob.glob(os.path.join(RESULTS_DIR, "**", "*_NAMES.txt"), recursive=True)

if not all_files:
    print("ERROR: No result files (*_NAMES.txt) found.")
    print("Please check if the BAT pipeline has finished or if the path is correct.")
    exit()

print(f"Found {len(all_files)} sample files.")

dfs = []

for filename in all_files:
    try:
        # Read individual file
        df = pd.read_csv(filename, sep='\t')
        
        # Add 'Sample' column based on folder name
        # e.g., .../ERR12345/ERR12345.bin2classification... -> Sample = ERR12345
        sample_name = os.path.basename(os.path.dirname(filename))
        df.insert(0, 'Sample', sample_name)
        
        dfs.append(df)
    except Exception as e:
        print(f"Warning: Error reading {filename}. Skipping. Error: {e}")

if dfs:
    final_df = pd.concat(dfs, ignore_index=True)
    
    # Save as TSV
    final_df.to_csv(OUTPUT_FILE, sep='\t', index=False)
    
    print("-" * 30)
    print("SUCCESS!")
    print(f"Master table created with {len(final_df)} bins.")
    print(f"Saved to: {OUTPUT_FILE}")
    print("-" * 30)
else:
    print("No data was merged.")