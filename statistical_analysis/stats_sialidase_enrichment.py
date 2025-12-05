import pandas as pd
import scipy.stats as stats
import statsmodels.stats.multitest as multitest
import os

INPUT_FILE = "/home/marcos/PRJEB59406/tabela_mestra_mag_sialidase.xlsx"
OUTPUT_DIR = "/home/marcos/PRJEB59406/abundance_results/stats"
os.makedirs(OUTPUT_DIR, exist_ok=True)

def clean_name(tax_string):
    if pd.isna(tax_string): return "Unclassified"
    parts = tax_string.split(";")
    for part in parts:
        if part.startswith("s__"): return part.replace("s__", "").replace("_", " ")
    return "Unknown"

def main():
    print("1. Carregando dados...")
    df = pd.read_excel(INPUT_FILE)
    
    df['Species'] = df['classification'].apply(clean_name)
    
    df['Has_Gene'] = df['tem_sialidase'].apply(lambda x: 1 if x == 'SIM' else 0)

    results = []
    
    species_list = df['Species'].value_counts()
    species_to_test = species_list[species_list >= 3].index

    print(f"2. Rodando Teste de Fisher para {len(species_to_test)} espécies...")

    total_mags = len(df)
    total_with_gene = df['Has_Gene'].sum()
    total_without_gene = total_mags - total_with_gene

    for species in species_to_test:
        df_species = df[df['Species'] == species]
        n_species_with = df_species['Has_Gene'].sum()
        n_species_without = len(df_species) - n_species_with
        
        df_others = df[df['Species'] != species]
        n_others_with = df_others['Has_Gene'].sum()
        n_others_without = len(df_others) - n_others_with
        
        table = [[n_species_with, n_species_without],
                 [n_others_with, n_others_without]]
        
        odds_ratio, p_value = stats.fisher_exact(table, alternative='greater')
        
        results.append({
            'Species': species,
            'Total_MAGs': len(df_species),
            'MAGs_with_Sialidase': n_species_with,
            'Perc_Positve': (n_species_with / len(df_species)) * 100,
            'P_Value': p_value,
            'Odds_Ratio': odds_ratio
        })

    if len(results) > 0:
        df_res = pd.DataFrame(results)
        df_res['P_Adj'] = multitest.multipletests(df_res['P_Value'], method='fdr_bh')[1]
        
        df_res = df_res.sort_values('P_Adj')
        
        outfile = os.path.join(OUTPUT_DIR, "statistical_sialidase_per_species.tsv")
        df_res.to_csv(outfile, sep="\t", index=False)
        
        print(df_res[['Species', 'Total_MAGs', 'Perc_Positve', 'P_Adj']].head(5))
        print(f"\nResultado salvo em: {outfile}")
    else:
        print("Not.")

if __name__ == "__main__":
    main()