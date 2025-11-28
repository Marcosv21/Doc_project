import glob
import re
import os

# Search for patterns like "ABC123.45" or "AB_123.45"
regex_codigo = r'\b([A-Z]{3}\d+\.\d+|[A-Z]{2}_\d+\.\d+)\b'

archive_list = glob.glob("*.txt")

print(f"Found {len(archive_list)} archives. Playing process...\n")

for input_archive in archive_list:
    if "_Results_" in input_archive: continue

    base_name = os.path.splitext(input_archive)[0]
    
    name_out_number = f"{base_name}_Number_Results.txt"
    name_out_complete = f"{base_name}_Complete_Results.txt"
    
    print(f"-> Processing: {input_archive}")
    
    count = 0
    
    try:
        with open(input_archive, 'r', encoding='latin-1') as f_in, \
             open(name_out_number, 'w') as f_num, \
             open(name_out_complete, 'w') as f_comp:
            
            for line in f_in:
                if "bacteria" in line.lower() and "ncbi" in line.lower():
                    
                    match = re.search(regex_codigo, line)
                    
                    if match:
                        codigo = match.group(0)
                        
                        f_num.write(f"{codigo}\n")      
                        f_comp.write(line)             
                        count += 1

        print(f"   OK! {count} Sequences saved as '{name_out_number}'")

    except Exception as e:
        print(f"   Error {input_archive}: {e}")

print("\nFinish!")