#!/bin/python
# Script Générer les inputs dans un fichier json pour lancer l'app regenie
import os
import json
import argparse


parser = argparse.ArgumentParser(description="generate_bgens_qc_input_json that takes one directory and one file as input.")
parser.add_argument(
    "-d", "--definitions_dir",
    dest="definitions_dir", type=str, required=True,
    help="Path to a local existing directory.")
parser.add_argument(
    "-g", "--genotype",
    dest="genotype", type=str, required=True,
    help="Name (prefix wo .bed/bim/fam) to a RAP hg38 existing genotpe.")
parser.add_argument(
    "-r", "--rap_install_dir",
    dest="rap_install_dir", type=str, required=True,
    help="Path to an existing directory on RAP")
parser.add_argument(
    "-p", "--pheno",
    dest="pheno", type=str, required=True,
    help="Path to an existing phenotype file on RAP")
args = parser.parse_args()

print(f"Creating regenie_input.json with\n   definitions_dir: {args.definitions_dir}\n   genotype: {args.genotype}\n   rap_install_dir: {args.rap_install_dir}\n   pheno: {args.pheno}\n")



# Chemins des fichiers génomiques principaux
bed = os.path.join(args.rap_install_dir, f'{args.genotype}.bed')
bim = os.path.join(args.rap_install_dir, f'{args.genotype}.bim')
fam = os.path.join(args.rap_install_dir, f'{args.genotype}.fam')

# Fonction pour générer les chemins triés
def sorted_paths(prefix, ext, n=22):
    return [f"{prefix}_c{chrom}_b0_v1.{ext}" for chrom in range(1, n + 1)]

# Générer les listes triées
bgen_paths = sorted_paths("/Bulk/Exome sequences/Population level exome OQFE variants, BGEN format - final release/ukb23159", "bgen")
bgi_paths = sorted_paths("/Bulk/Exome sequences/Population level exome OQFE variants, BGEN format - final release/ukb23159", "bgen.bgi")
sample_paths = sorted_paths("/Bulk/Exome sequences/Population level exome OQFE variants, BGEN format - final release/ukb23159", "sample")

# Autres fichiers d'entrée
pheno_txt = os.path.join(args.rap_install_dir, f'{args.pheno}')
covar_txt = pheno_txt
step1_snps = os.path.join(args.rap_install_dir, "final_array_snps_CRCh38_qc_pass.snplist")
step2_snps = os.path.join(args.rap_install_dir, "gel_impute_data_snps_qc_pass.snplist")

# Construction du dictionnaire d'inputs
inputs = {
    "wgr_genotype_bed": bed,
    "wgr_genotype_bim": bim,
    "wgr_genotype_fam": fam,
    "genotype_bgens": bgen_paths,
    "genotype_bgis": bgi_paths,
    "genotype_samples": sample_paths,
    "pheno_txt": pheno_txt,
    "step1_extract_txts": step1_snps,
    "step2_extract_txts": step2_snps,
    "step1_ref_first": True,
    "covar_txt": covar_txt,
    "quant_traits": False,
    "step1_block_size": 1000,
    "step2_block_size": 200,
    "pheno_names": "ad_by_proxy",
    "use_firth_approx": True,
    "min_mac": 3,
    "covar_names": "age,sex,pc1,pc2,pc3,pc4,pc5,pc6,pc7,pc8,pc9,pc10"
}

# Sauvegarde dans un fichier
ofn = os.path.join(args.definitions_dir, "regenie_input.json")
with open(ofn, "w") as f:
    json.dump(inputs, f, indent=2)