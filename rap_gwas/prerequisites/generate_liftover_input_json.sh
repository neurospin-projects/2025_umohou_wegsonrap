#!/bin/bash
# Script colleting all "dx" commands to be run from a dx-toolkit local shell.
set -euo pipefail 

# utils
red()    { echo -e "\e[31m$*\e[0m"; }
green()  { echo -e "\e[32m$*\e[0m"; }
yellow() { echo -e "\e[33m$*\e[0m"; }

if [ "${ROOT_INSTALL+x}" ]; then
  green "   ROOT_INSTALL:  $ROOT_INSTALL"
else
  red "   generate_liftover_input.sh: ROOT_INSTALL is not set"
fi


#### Parsing
rap_installdir=""

# Parse options
while getopts "i:" opt; do
  case $opt in
    i) rap_installdir="$OPTARG" ;;
    \?) echo "Usage: $0 -i <rap_installdir>"; exit 1 ;;
  esac
done
# Check if mandatory arguments are provided
if [[ -z "$rap_installdir"  ]]; then
    echo -e "\e[31mError: -i <rap_installdir> is required.\e[0m"
    echo -e "\e[31mUsage: $0 -i <rap_installdir>.\e[0m"
    echo ""
  exit 1
fi

# Pushing the resources in TMPDIR
#################################
green "   Pushing hg38.fa and b37ToHg38.over.chain to RAP central:  $rap_installdir/"
dx upload $ROOT_INSTALL/resources/hg38.fa  --no-progress --destination "$rap_installdir/"
dx upload $ROOT_INSTALL/resources/b37ToHg38.over.chain  --no-progress --destination "$rap_installdir/"


# Getting dnanexus descriptions 
################################
mkdir -p "$ROOT_INSTALL/definitions"
output_file="$ROOT_INSTALL/definitions/liftover_input.json"
green "   Generating $output_file in $ROOT_INSTALL/definitions"


#  Liste des fichiers avec leur clé JSON et chemin DNAnexus 
declare -A single_files=(
  ["stage-common.reference_fastagz"]="/tmp/hg38.fa"
  ["stage-common.ucsc_chain"]="/tmp/b37ToHg38.over.chain"
)

#  Listes de fichiers (ex: plink_beds, bims, fams) 
declare -A plink_paths=(
  ["stage-common.plink_beds"]="
\"/Bulk/Genotype Results/Genotype calls/ukb22418_c1_b0_v2.bed\"
\"/Bulk/Genotype Results/Genotype calls/ukb22418_c2_b0_v2.bed\"
\"/Bulk/Genotype Results/Genotype calls/ukb22418_c3_b0_v2.bed\"
\"/Bulk/Genotype Results/Genotype calls/ukb22418_c4_b0_v2.bed\"
\"/Bulk/Genotype Results/Genotype calls/ukb22418_c5_b0_v2.bed\"
\"/Bulk/Genotype Results/Genotype calls/ukb22418_c6_b0_v2.bed\"
\"/Bulk/Genotype Results/Genotype calls/ukb22418_c7_b0_v2.bed\"
\"/Bulk/Genotype Results/Genotype calls/ukb22418_c8_b0_v2.bed\"
\"/Bulk/Genotype Results/Genotype calls/ukb22418_c9_b0_v2.bed\"
\"/Bulk/Genotype Results/Genotype calls/ukb22418_c10_b0_v2.bed\"
\"/Bulk/Genotype Results/Genotype calls/ukb22418_c11_b0_v2.bed\"
\"/Bulk/Genotype Results/Genotype calls/ukb22418_c12_b0_v2.bed\"
\"/Bulk/Genotype Results/Genotype calls/ukb22418_c13_b0_v2.bed\"
\"/Bulk/Genotype Results/Genotype calls/ukb22418_c14_b0_v2.bed\"
\"/Bulk/Genotype Results/Genotype calls/ukb22418_c15_b0_v2.bed\"
\"/Bulk/Genotype Results/Genotype calls/ukb22418_c16_b0_v2.bed\"
\"/Bulk/Genotype Results/Genotype calls/ukb22418_c17_b0_v2.bed\"
\"/Bulk/Genotype Results/Genotype calls/ukb22418_c18_b0_v2.bed\"
\"/Bulk/Genotype Results/Genotype calls/ukb22418_c19_b0_v2.bed\"
\"/Bulk/Genotype Results/Genotype calls/ukb22418_c20_b0_v2.bed\"
\"/Bulk/Genotype Results/Genotype calls/ukb22418_c21_b0_v2.bed\"
\"/Bulk/Genotype Results/Genotype calls/ukb22418_c22_b0_v2.bed\"
\"/Bulk/Genotype Results/Genotype calls/ukb22418_cMT_b0_v2.bed\"
\"/Bulk/Genotype Results/Genotype calls/ukb22418_cX_b0_v2.bed\"
\"/Bulk/Genotype Results/Genotype calls/ukb22418_cXY_b0_v2.bed\"
\"/Bulk/Genotype Results/Genotype calls/ukb22418_cY_b0_v2.bed\"
"
  ["stage-common.plink_bims"]="
\"/Bulk/Genotype Results/Genotype calls/ukb22418_c1_b0_v2.bim\"
\"/Bulk/Genotype Results/Genotype calls/ukb22418_c2_b0_v2.bim\" 
\"/Bulk/Genotype Results/Genotype calls/ukb22418_c3_b0_v2.bim\"
\"/Bulk/Genotype Results/Genotype calls/ukb22418_c4_b0_v2.bim\" 
\"/Bulk/Genotype Results/Genotype calls/ukb22418_c5_b0_v2.bim\" 
\"/Bulk/Genotype Results/Genotype calls/ukb22418_c6_b0_v2.bim\" 
\"/Bulk/Genotype Results/Genotype calls/ukb22418_c7_b0_v2.bim\" 
\"/Bulk/Genotype Results/Genotype calls/ukb22418_c8_b0_v2.bim\" 
\"/Bulk/Genotype Results/Genotype calls/ukb22418_c9_b0_v2.bim\" 
\"/Bulk/Genotype Results/Genotype calls/ukb22418_c10_b0_v2.bim\" 
\"/Bulk/Genotype Results/Genotype calls/ukb22418_c11_b0_v2.bim\" 
\"/Bulk/Genotype Results/Genotype calls/ukb22418_c12_b0_v2.bim\" 
\"/Bulk/Genotype Results/Genotype calls/ukb22418_c13_b0_v2.bim\" 
\"/Bulk/Genotype Results/Genotype calls/ukb22418_c14_b0_v2.bim\" 
\"/Bulk/Genotype Results/Genotype calls/ukb22418_c15_b0_v2.bim\" 
\"/Bulk/Genotype Results/Genotype calls/ukb22418_c16_b0_v2.bim\" 
\"/Bulk/Genotype Results/Genotype calls/ukb22418_c17_b0_v2.bim\" 
\"/Bulk/Genotype Results/Genotype calls/ukb22418_c18_b0_v2.bim\" 
\"/Bulk/Genotype Results/Genotype calls/ukb22418_c19_b0_v2.bim\" 
\"/Bulk/Genotype Results/Genotype calls/ukb22418_c20_b0_v2.bim\" 
\"/Bulk/Genotype Results/Genotype calls/ukb22418_c21_b0_v2.bim\" 
\"/Bulk/Genotype Results/Genotype calls/ukb22418_c22_b0_v2.bim\" 
\"/Bulk/Genotype Results/Genotype calls/ukb22418_cMT_b0_v2.bim\" 
\"/Bulk/Genotype Results/Genotype calls/ukb22418_cX_b0_v2.bim\" 
\"/Bulk/Genotype Results/Genotype calls/ukb22418_cXY_b0_v2.bim\" 
\"/Bulk/Genotype Results/Genotype calls/ukb22418_cY_b0_v2.bim\"
" 
  ["stage-common.plink_fams"]="
\"/Bulk/Genotype Results/Genotype calls/ukb22418_c1_b0_v2.fam\" 
\"/Bulk/Genotype Results/Genotype calls/ukb22418_c2_b0_v2.fam\" 
\"/Bulk/Genotype Results/Genotype calls/ukb22418_c3_b0_v2.fam\" 
\"/Bulk/Genotype Results/Genotype calls/ukb22418_c4_b0_v2.fam\" 
\"/Bulk/Genotype Results/Genotype calls/ukb22418_c5_b0_v2.fam\"
\"/Bulk/Genotype Results/Genotype calls/ukb22418_c6_b0_v2.fam\" 
\"/Bulk/Genotype Results/Genotype calls/ukb22418_c7_b0_v2.fam\" 
\"/Bulk/Genotype Results/Genotype calls/ukb22418_c8_b0_v2.fam\" 
\"/Bulk/Genotype Results/Genotype calls/ukb22418_c9_b0_v2.fam\" 
\"/Bulk/Genotype Results/Genotype calls/ukb22418_c10_b0_v2.fam\" 
\"/Bulk/Genotype Results/Genotype calls/ukb22418_c11_b0_v2.fam\" 
\"/Bulk/Genotype Results/Genotype calls/ukb22418_c12_b0_v2.fam\" 
\"/Bulk/Genotype Results/Genotype calls/ukb22418_c13_b0_v2.fam\" 
\"/Bulk/Genotype Results/Genotype calls/ukb22418_c14_b0_v2.fam\" 
\"/Bulk/Genotype Results/Genotype calls/ukb22418_c15_b0_v2.fam\" 
\"/Bulk/Genotype Results/Genotype calls/ukb22418_c16_b0_v2.fam\" 
\"/Bulk/Genotype Results/Genotype calls/ukb22418_c17_b0_v2.fam\" 
\"/Bulk/Genotype Results/Genotype calls/ukb22418_c18_b0_v2.fam\" 
\"/Bulk/Genotype Results/Genotype calls/ukb22418_c19_b0_v2.fam\" 
\"/Bulk/Genotype Results/Genotype calls/ukb22418_c20_b0_v2.fam\" 
\"/Bulk/Genotype Results/Genotype calls/ukb22418_c21_b0_v2.fam\" 
\"/Bulk/Genotype Results/Genotype calls/ukb22418_c22_b0_v2.fam\" 
\"/Bulk/Genotype Results/Genotype calls/ukb22418_cMT_b0_v2.fam\" 
\"/Bulk/Genotype Results/Genotype calls/ukb22418_cX_b0_v2.fam\" 
\"/Bulk/Genotype Results/Genotype calls/ukb22418_cXY_b0_v2.fam\" 
\"/Bulk/Genotype Results/Genotype calls/ukb22418_cY_b0_v2.fam\"
"
)

#### Construction du JSON
#### FIXIT : this code to be simplified : chatGPT is stupid
echo "{" > "$output_file"

#  Fichiers multiples 
for key in "${!plink_paths[@]}"; do
  echo "  \"$key\": [" >> "$output_file"
  # Utilise un here-string et `while read` pour lire chaque chemin ligne par ligne.
  while IFS= read -r path; do
    # Supprime les guillemets externes s'ils ont été ajoutés pour la déclaration
    path=$(echo "$path" | tr -d '"' | xargs echo -n) # xargs -n pour nettoyer les espaces
    
    # Vérifie si le chemin n'est pas vide (pour éviter les lignes vides de la déclaration)
    if [[ -n "$path" ]]; then
      file_id=$(dx describe "$path" --json | jq -r '.id')
      echo "    {\"\$dnanexus_link\": \"$file_id\"}," >> "$output_file"
    fi
  done <<< "${plink_paths[$key]}"
  sed -i '$ s/,$//' "$output_file"  # retirer la dernière virgule de la liste
  echo "  ]," >> "$output_file"
done

#  Fichiers simples 
for key in "${!single_files[@]}"; do
  dx_path="${single_files[$key]}"
  file_id=$(dx describe "$dx_path" --json | jq -r '.id')
  echo "  \"$key\": {\"\$dnanexus_link\": \"$file_id\"}," >> "$output_file"
done

#  Ajouter la valeur textuelle finale 
echo "  \"stage-common.split_par_build_code\": \"hg38\"" >> "$output_file"
echo "}" >> "$output_file"

echo -e "\e[32m   $output_file successfully generated\e[0m"