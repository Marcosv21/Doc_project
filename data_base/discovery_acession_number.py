import re
import glob
import os

# --- CONFIGURAÇÃO DE FILTRO (BACTÉRIA vs O RESTO) ---
# O script assume que é Bactéria, a menos que encontre estas palavras na linha:
NON_BACTERIA_KEYWORDS = [
    "Virus", "Phage", "Influenza", "Paramyxovirus", "Newcastle", "Coronavir", # Vírus
    "Homo", "Mus", "Rattus", "Bos", "Sus", "Gallus", "Danio", "Xenopus", "Human", "C. elegans", # Animais
    "Arabidopsis", "Oryza", "Zea", "Nicotiana", # Plantas
    "Saccharomyces", "Candida", "Aspergillus", "Neurospora", "Yeast", "Fungi", # Fungos
    "Trypanosoma", "Leishmania", "Plasmodium", # Protozoários
    "Methano", "Pyrococcus", "Sulfolobus", "Thermococcus", "Archaea" # Arqueas
]

def is_likely_bacteria(line):
    """Retorna False se encontrar palavras de vírus/eucariotos. Retorna True caso contrário."""
    for keyword in NON_BACTERIA_KEYWORDS:
        if keyword.lower() in line.lower():
            return False 
    return True 

def process_cazy_files(file_list):
    # Conjuntos (Sets) para guardar os códigos sem repetição
    ncbi_bacteria = set()
    ncbi_non_bacteria = set()
    uniprot_bacteria = set()
    uniprot_non_bacteria = set()

    # Regex (Padrões de Identificação)
    # NCBI: 3 letras + 5-7 números (AAA12345) OU RefSeq (WP_123456)
    regex_ncbi = r'\b([A-Z]{3}\d{5,7}(?:\.\d+)?|[A-Z]{2}_\d{6,9}(?:\.\d+)?)\b'
    
    # UniProt: Padrões específicos (Ex: Q9XYZ1, A0A0A0)
    regex_uniprot = r'\b([A-N,R-Z][0-9](?:[A-Z][A-Z0-9]{2}[0-9]){1,2}|[O,P,Q][0-9][A-Z0-9]{3}[0-9])\b'

    print(f"Arquivos encontrados para processar: {len(file_list)}")
    for f in file_list:
        print(f" -> Lendo: {f}")

    # Loop principal de leitura
    for file_path in file_list:
        try:
            with open(file_path, 'r', encoding='latin-1') as f:
                lines = f.readlines()

            for line in lines:
                if len(line) < 10: continue # Pula linhas vazias ou muito curtas

                # Define se a linha atual parece ser de bactéria
                is_bact = is_likely_bacteria(line)

                # 1. Extração NCBI
                matches_ncbi = re.findall(regex_ncbi, line)
                for acc in matches_ncbi:
                    # Filtro extra para evitar falsos positivos (ex: PDB IDs)
                    if "_" in acc or (len(acc) >= 6 and acc[0].isalpha()):
                        if is_bact:
                            ncbi_bacteria.add(acc)
                        else:
                            ncbi_non_bacteria.add(acc)

                # 2. Extração UniProt
                # (Procuramos UniProt separadamente para não misturar)
                matches_uniprot = re.findall(regex_uniprot, line)
                for acc in matches_uniprot:
                    if len(acc) in [6, 10]: # UniProt padrão tem 6 ou 10 caracteres
                         if is_bact:
                            uniprot_bacteria.add(acc)
                         else:
                            uniprot_non_bacteria.add(acc)

        except Exception as e:
            print(f"ERRO ao ler {file_path}: {e}")

    # --- FUNÇÃO PARA SALVAR ---
    def save_list(data_set, filename):
        if not data_set:
            return # Não cria arquivo vazio
        with open(filename, 'w') as f:
            for item in sorted(list(data_set)):
                f.write(f"{item}\n")
        print(f"Salvo: {filename} ({len(data_set)} códigos)")

    print("\n" + "="*30)
    print("RELATÓRIO DE EXTRAÇÃO")
    print("="*30)
    
    save_list(ncbi_bacteria, "Result_NCBI_Bacteria.txt")
    save_list(ncbi_non_bacteria, "Result_NCBI_Outros.txt")
    save_list(uniprot_bacteria, "Result_UniProt_Bacteria.txt")
    save_list(uniprot_non_bacteria, "Result_UniProt_Outros.txt")

# --- EXECUÇÃO PRINCIPAL ---

# Aqui está o input que procura pelo padrão .cazy.txt
padrao_busca = "*.cazy.txt"
arquivos_encontrados = glob.glob(padrao_busca)

if len(arquivos_encontrados) == 0:
    print(f"ERRO: Nenhum arquivo terminado em '{padrao_busca}' foi encontrado na pasta atual.")
    print("Verifique se você renomeou os arquivos corretamente (ex: GH33.cazy.txt)")
else:
    process_cazy_files(arquivos_encontrados)