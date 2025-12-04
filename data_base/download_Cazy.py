import time
import os
import glob
from Bio import Entrez

# --- CONFIGURAÇÃO ---
Entrez.email = "marcos.vinicius.c2151@gmail.com"  
INPUT_DIR = "/home/marcos/PRJEB59406/Data_base" 
OUTPUT_FILE = "/home/marcos/PRJEB59406/Data_base/cazy_database_ncbi.fasta"
BATCH_SIZE = 100 
# --------------------

def download_sequences():
    # 1. Encontrar arquivos
    search_path = os.path.join(INPUT_DIR, "*.txt")
    files = glob.glob(search_path)
    
    if not files:
        print(f"ERROR: Not found .txt in: {INPUT_DIR}")
        return

    all_ids = set()
    ignored_count = 0
    bacteria_count = 0
    
    for txt_file in files:
        print(f"   - Lendo: {os.path.basename(txt_file)}")
        try:
            with open(txt_file, "r") as f:
                for line in f:
                    parts = line.strip().split()
                    
                    if len(parts) > 2:
                        kingdom = parts[1]            # Pega a segunda palavra da linha
                        db_source = parts[-1].lower() # Pega a última palavra
                        accession_id = parts[-2]      # Pega a penúltima palavra
                        if kingdom == "Bacteria" and ('ncbi' in db_source or 'genbank' in db_source):
                            all_ids.add(accession_id)
                            bacteria_count += 1
                        else:
                            ignored_count += 1
                            
        except Exception as e:
            print(f"Error: {txt_file}: {e}")

    final_id_list = sorted(list(all_ids))
    total_ids = len(final_id_list)
    
    print(f"bacteria IDs: {total_ids}")
    
    if total_ids == 0:
        print("bacteria in NCBI not found.")
        return

    print(f"\n Starting download {total_ids} sequences...")
    
    with open(OUTPUT_FILE, "w") as out_handle:
        for start in range(0, total_ids, BATCH_SIZE):
            end = min(total_ids, start + BATCH_SIZE)
            batch_ids = final_id_list[start:end]
            
            print(f"   Download {start+1} a {end}...")
            
            try:
                handle = Entrez.efetch(db="protein", 
                                       id=batch_ids, 
                                       rettype="fasta", 
                                       retmode="text")
                
                out_handle.write(handle.read())
                handle.close()
                time.sleep(0.5)
                
            except Exception as e:
                print(f"   Fail {start}-{end}: {e}")
                with open("failed_batches_log.txt", "a") as log:
                    log.write(f"Lote {start}-{end} falhou. Erro: {e}\nIDs: {batch_ids}\n")

    print(f"\n Finish: {OUTPUT_FILE}")

if __name__ == "__main__":
    download_sequences()