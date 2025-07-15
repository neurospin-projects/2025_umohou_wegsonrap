#!/bin/env bash

echo "fetch_resources.sh will fetch files of interest for the treatments,"
echo "as well as WDL code (clone github directory)."

# file=""
# output=""

# # Parse options
# while getopts "f:o:" opt; do
#   case $opt in
#     f) file="$OPTARG" ;;
#     o) output="$OPTARG" ;;
#     \?) echo "Usage: $0 -f <file> [-o <output>]"; exit 1 ;;
#   esac
# done

# # Print parsed values
# echo "File: $file"
# echo "Output: $output"


liftover_wdl_install() {

    wget -O $1/liftover_plink_beds.wdl https://github.com/dnanexus-rnd/liftover_plink_beds/raw/refs/heads/main/liftover_plink_beds.wdl -q --show-progress
    echo -e "\e[32m   liftover WDL pipeline fetched in $1.\e[0m"
}

reference_fastagz_install() {

    wget -O $1/hg38.fa.gz https://hgdownload.soe.ucsc.edu/goldenPath/hg38/bigZips/hg38.fa.gz -q --show-progress
    gunzip -f $1/hg38.fa.gz
    echo -e "\e[32m   reference_fastagz fetched and uncompressed in $1.\e[0m"
}

ucsc_chain_install() {

    wget -O $1/b37ToHg38.over.chain https://raw.githubusercontent.com/broadinstitute/gatk/master/scripts/funcotator/data_sources/gnomAD/b37ToHg38.over.chain -q --show-progress
    echo -e "\e[32m   ucsc_chain fetched in $1.\e[0m"
}

bgens_qc_install() {

    wget -O $1/bgens_qc.wdl https://github.com/dnanexus/UKB_RAP/raw/refs/heads/main/end_to_end_gwas_phewas/bgens_qc/bgens_qc.wdl -q --show-progress
    echo -e "\e[32m   bgens_qc WDL pipeline fetched in $1.\e[0m"
}

#### Parsing
installdir=""

# Parse options
while getopts "i:" opt; do
  case $opt in
    i) installdir="$OPTARG" ;;
    \?) echo "Usage: $0 -i <installdir>"; exit 1 ;;
  esac
done
# Check if mandatory arguments are provided
if [[ -z "$installdir"  ]]; then
    echo -e "\e[31mError: -i <installdir> is required.\e[0m"
    echo -e "\e[31mUsage: $0 -i <installdir>.\e[0m"
    echo ""
  exit 1
fi
# Print parsed values
# echo "Will install the liftover_plink_beds.wdl in : $installdir/resources"
# echo "Will install the hg38.fa.gz in : $installdir/resources"
# echo "Will install the b37ToHg38.over.chain in : $installdir/resources"
# echo "Will install the bgens_qc.wdl in : $installdir/resources"
# mkdir -p $installdir/resources

#### Installing cmd
mkdir -p $installdir/resources
liftover_wdl_install $installdir/resources
reference_fastagz_install $installdir/resources
ucsc_chain_install $installdir/resources
bgens_qc_install $installdir/resources