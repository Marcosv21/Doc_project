import pandas as pd
import glob
import os
# Define the column names for the DIAMOND output TSV files
columns = [
    'seqid','sseqid','pident','length','mismatch','gapopen',
    'qstart','qend','sstart','send','evalue','bitscore','qlen','slen'
]
# Define input and output directories
INPUT_DIR = "/temporario2/17404478/PRJEB59406/diamond_results"
OUTPUT_DIR = "/temporario2/17404478/PRJEB59406/diamond_results_filtrados"
os.makedirs(OUTPUT_DIR, exist_ok=True)
# Get list of TSV files in the input directory
document = glob.glob(os.path.join(INPUT_DIR, "*.tsv"))
# Process each TSV file
for arc in document: 
    base_name = os.path.basename(document) 
    print(f"-> Processing: {base_name}") 
    
    try: 
        df = pd.read_csv(arc, sep="\t", names=columns, header=None, 
                         usecols=range(14), low_memory=False) 
        # Convert specified columns to numeric types
        cols_num = ['pident', 'length', 'evalue', 'bitscore', 'qlen', 'slen']
        
        for col in cols_num: 
            df[col] = pd.to_numeric(df[col], errors='coerce')
# Remove rows with NaN values in numeric columns            
        before_line = len(df) 
        df = df.dropna(subset=cols_num) 
        # Verify if DataFrame is empty after dropping NaNs
        if len(df) == 0: 
            continue 

        df['cobertura'] = df['length'] / df['qlen'] 
        df['qlen/slen'] = df['qlen'] / df['slen'] 
# Apply filtering criteria
        filter = (
            (df['pident'] >= 40) &
            (df['evalue'] <= 1e-4) &
            (df['cobertura'] >= 0.5) &
            (df['qlen/slen'] >= 0.7) &
            (df['qlen/slen'] <= 1.5) &
            (df['bitscore'] >= 50)
        )
        
        final_df = df[filter] 

        output_pat = os.path.join(OUTPUT_DIR, base_name) 
        final_df.to_csv(output_pat, sep="\t", index=False) 
# Indicate complete d processing
    except Exception as e: 
        print(f"   ERROR IN {base_name}: {e}") 

print("Finish!")