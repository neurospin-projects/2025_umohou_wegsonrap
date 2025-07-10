#!/bin/bash
# Script collecting all "dx run" commands to be run from a dx-toolkit local shell.

cd $ROOT_INSTALL
TMPDIR=$(mktemp -d -p /tmp tmpregenieadbyproxy.XXXXXX)
dx mkdir $TMPDIR

# Step1
#######
# prolog to select field and obtain a file for table exporter
    ret=$($DIST_INSTALL/prerequisites/build-ns-app.sh $ROOT_INSTALL/scripts/ns-app-selectfield)
    appret=$(echo $ret | grep -o 'applet-[a-zA-Z0-9]\+' | grep -v 'applet-id')
dx run --priority high $appret -ioutprefix=selected_fields -ioutput_folder="$TMPDIR" -y --watch

# Table exporter
dx run table-exporter \
    -idataset_or_cohort_or_dashboard=app64984_20250411144839.dataset \
    -ifield_names_file_txt="$TMPDIR/selected_fields.csv" \
    -ientity=participant \
    -icoding_option=RAW \
    -ioutput=raw_extract \
    --destination "$TMPDIR" --priority high -y --watch

# Munge the raw_extract.csv file to run Alz Dis by proxy algo. Modified from the notebook
# to accomodate the software envir available on "dx app" vs "dx sparkjupyter"
    ret=$($DIST_INSTALL/prerequisites/build-ns-app.sh $ROOT_INSTALL/scripts/ns-app-getadproxy)
    appret=$(echo $ret | grep -o 'applet-[a-zA-Z0-9]\+' | grep -v 'applet-id')
dx run --priority high $appret -itabexport_with_icd="$TMPDIR/raw_extract.csv" -ioutputprefix="ad_risk_by_proxy_wes" -ioutput_folder="$TMPDIR" -y --watch

# Step2 
#######
if dx find data --name "ukb_c1-22_hg38_merged.bim" --folder "/commons/references"  --brief | grep -q .; then
    echo "liftover hg38 files version already exist. Skip this step";
else
    #To perform the liftover on bed, bim, fam files from Genotype calls folder. 
    #The liftover_input.json file is generated via the sh file generate_liftover_input_json.sh
        ret=$(dxCompiler compile $ROOT_INSTALL/resources/liftover_plink_beds.wdl --project project-Gxv2Xz0J01k1gpZV8FgPF6pq --destination "$TMPDIR/")
        wflret=$(echo $ret | grep -o 'workflow-[a-zA-Z0-9]\+' | grep -v 'workflow-id')
        $DIST_INSTALL/prerequisites/generate_liftover_input_json.sh -i $TMPDIR
    dx run --priority high $wflret -f $ROOT_INSTALL/definitions/liftover_input.json --brief -y --watch --destination "$TMPDIR/"

    # move to references resources  "$TMPDIR/ukb_hg38_merged.*"
    dx mv "$TMPDIR/ukb_hg38_merged.*" /commons/references/hg38_liftover/
    dx mv "$TMPDIR/ukb_c*_hg38.*" /commons/references/hg38_liftover/
    dx mv "$TMPDIR/ukb_unplaced_hg38.*" /commons/references/hg38_liftover/
    dx mv "$TMPDIR/ukb_c1-22_hg38_merged.*" /commons/references/hg38_liftover/
    dx mv "$TMPDIR/*vcf.gz" /commons/references/hg38_liftover/
    dx mv "$TMPDIR/ukb*_c*hg38.*" /commons/references/hg38_liftover/
fi

# Step3 
#######

#To perform the quality control step on both array genotype data and WES data
    # For array genotype data with plink
    # -----------------------
    nproc=8
    dx run app-swiss-army-knife  \
        -iin="/commons/references/ukb_c1-22_hg38_merged.bim" \
        -iin="/commons/references/ukb_c1-22_hg38_merged.bed" \
        -iin="/commons/references/ukb_c1-22_hg38_merged.fam" \
        -icmd="plink2 --bfile ukb_c1-22_hg38_merged --out final_array_snps_CRCh38_qc_pass --mac 100 --maf 0.01 --hwe 1e-15 --mind 0.1 --geno 0.1 --write-snplist --write-samples --no-id-header --threads $(nproc)" \
        --destination "$TMPDIR/" --priority high -y --watch


    # For WES data with bgens_qc.wdl
    # ------------
    # First generate the json file meta information for the pipeline 
    $DIST_INSTALL/prerequisites/generate_bgens_qc_input_json.py -d $ROOT_INSTALL/definitions -r $TMPDIR -p ad_risk_by_proxy_wes.phe
    ret=$(dxCompiler compile  $ROOT_INSTALL/resources/bgens_qc.wdl -inputs $ROOT_INSTALL/definitions/bgens_qc_input.json -archive -folder "$TMPDIR/")
    wflret=$(echo $ret | grep -o 'workflow-[a-zA-Z0-9]\+' | grep -v 'workflow-id')
    dx run --priority high $wflret -f $ROOT_INSTALL/definitions/bgens_qc_input.dx.json --destination "$TMPDIR/"

# Step4 
#######

# We perform this part in only one step because if we wanted to do it in two steps, the second one would require a set of three files(bgen, bgen.bgi, sample) 
#by chromosome, meaning that we would run the code 22 times.
$DIST_INSTALL/prerequisites/generate_regenie_input_json.py -d $ROOT_INSTALL/definitions -r $TMPDIR -p ad_risk_by_proxy_wes.phe -g ukb_c1-22_hg38_merged
dx run app-regenie -f $ROOT_INSTALL/definitions/regenie_input.json --destination "$TMPDIR/" --priority high -y --watch
