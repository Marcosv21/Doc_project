import pandas as pd
import seaborn as sns
import matplotlib.pyplot as plt
import os

INPUT_FILE = "/home/marcos/PRJEB59406/tabela_mestra_mag_sialidase.xlsx"
OUTPUT_DIR = "/home/marcos/PRJEB59406/abundance_results/plots_comparativos"
os.makedirs(OUTPUT_DIR, exist_ok=True)

def clean_gtdb_name(tax_string):
    if pd.isna(tax_string): return "Unclassified"
    
    parts = tax_string.split(";")
    species = ""
    genus = ""
    
    for part in parts:
        if part.startswith("g__"): genus = part.replace("g__", "")
        if part.startswith("s__"): species = part.replace("s__", "")
    
    if species and len(species) > 0:
        return species.replace("_", " ") # Format species name
    
    if genus:
        return f"{genus} sp."
        
    return "Unknown Bacteria"

def main():
    print(f"Lendo dados de: {INPUT_FILE}")
    df = pd.read_excel(INPUT_FILE)
    
    df['Species_Label'] = df['classification'].apply(clean_gtdb_name)
    
    order = df['Species_Label'].value_counts().index
    
    if len(order) > 30:
        print(f" ({len(order)}). Top 30.")
        order = order[:30]
        df = df[df['Species_Label'].isin(order)]

    plt.figure(figsize=(10, 12)) 
    sns.set_theme(style="whitegrid")

    custom_palette = {
        'YES': '#2ca25f',    
        'NOT': '#bdbdbd',    
        'NOT FOUND': '#f0f0f0' 
    }

    ax = sns.countplot(data=df, y='Species_Label', hue='tem_sialidase', 
                       order=order, palette=custom_palette, dodge=False)

    plt.title("Taxonomy of recovered MAGs and Sialidase presence", fontsize=16, pad=20)
    plt.xlabel("Number of recovered Genomes (MAGs)", fontsize=12)
    plt.ylabel("Species (GTDB-Tk)", fontsize=12)
    
    plt.yticks(fontstyle='italic')
    
    plt.legend(title='Has sialidase?', loc='lower right')
    
    # Add numbers on bars
    for container in ax.containers:
        ax.bar_label(container, padding=3)

    plt.tight_layout()
    
    outfile = os.path.join(OUTPUT_DIR, "sial_mag_tax.png")
    plt.savefig(outfile, dpi=300)
    print(f"Save graph in: {outfile}")

if __name__ == "__main__":
    main()