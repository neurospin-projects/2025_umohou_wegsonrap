# A re-worked example of GWAS on DNAnexus RAP

## Introduction
What is presented here is derived from the original work from the "Science Corner of UKBiobank RAP documentation": [GWAS guide using Alzheimer's disease](https://dnanexus.gitbook.io/uk-biobank-rap/science-corner/gwas-using-alzheimers-disease).
 
 We intend to clarify the different parts of the script by separating the preparation of the data required for processing, from the processing itself. This can be read in the two scripts:
 - rap_gwas/prerequisites/install_gwas_ad_proxy.sh
 - rap_gwas/prerequisites/batch_gwas_ad_proxy.sh

## Rationale
The reworked example covers the situation where the phenotype has to be extracted from the tabular data and tentatively associated with genetics.

Four parts can be distinguished in the original [document](https://dnanexus.gitbook.io/uk-biobank-rap/science-corner/gwas-using-alzheimers-disease): 
1. A notebook  (using jupyter-sparkl kernel) that would interact with RAP-central to 
   1. get information from the sql (tabular) data and 
   2. the s3 data-dictionary file
2. A WDL Workflow data language script that implement the liftover
3. A SwissArmyKnife list of commands to perform QC
4. A dx run call to the Regenie App (available from RAP-Central)


The objective is to wrap-up in a single script those 4 steps that currently run using heterogeneous interfaces.

## How to extract a phenotype and run a gwas

### Install and run the pixi (python) environment
To execute these scripts, you need to have a regular acces to the DNAnexus RAP system that come along with a regular UK Biobank regular project.

Have a few tools installed:
- pixi (see [here](https://pixi.sh/dev/installation/)]),
- Java should be installed too.

You may now clone the project.

```bash
# git clone this repo
git clone https://github.com/neurospin-projects/2025_umohou_wegsonrap.git

# start the pixi env
pixi shell --manifest-path ./2025_umohou_wegsonrap/envs/dxtoolkit/pixi.toml 

# Finalize the system tools installation : jq and dxCompiler !
# will install them in  
sh ./2025_umohou_wegsonrap/utils/isntaller.sh
```

### Set important environment variables:
Two variables are required to execute correctly the scripts of the reworked code:
- **DIST_INSTALL**: the path to cloned repo entry
- **ROOT_INSTALL**: the path to the place where you will build the local resources required to interact with the process that will run on the UKBiobank-RAP.

```bash
export DIST_INSTALL=./2025_umohou_wegsonrap/rap_gwas
export ROOT_INSTALL=/tmp/alz_pheno

mkdir $ROOT_INSTALL
```
### Instantiate the resources required

The code to run is below. Please execute the different step of this file first.

```bash
sh $DIST_INSTALL/prerequisites/install_gwas_ad_proxy.sh
```

Two user defined apps are used and there creation is described here and coded in the script. See [howto build an app](https://academy.dnanexus.com/buildingapplets/python/python_wc) from dnanexus documentation.

A third ndanexus app is also used: table-exporter.

<details><summary>Expand for details the user define apps: ns-app-selectfield and ns-app-getadproxy</summary>


#### ns-app-selectfields

This app will manage the query of the data-dictionary file available from RAP-central. The data disctionnary starts from the "datasource" which is the "refreshable" view of the UK Biobank data.

Set a ROOT_INSTALL variable
```bash
export DIST_INSTALL=<git-entry>/full_pipelines/GWAS_AD_PROXY
export ROOT_INSTALL=/tmp/alz_pheno

mkdir $ROOT_INSTALL/scripts
```

Create the template for the app. The wizard will create a skeleton. The input and output variables of the app are specified in $DIST_INSTALL/prerequisites/selectfield.json

```bash
cd $ROOT_INSTALL/scripts
rm -rf $ROOT_INSTALL/scripts/ns-app-selectfield
dx-app-wizard --json-file $DIST_INSTALL/prerequisites/selectfield.json << EOF


20m
Python
y
y
mem1_ssd1_v2_x16
EOF
# answer are the defaults value, 
# but Python for language, 
# but Internet (yes)
# but access projec (yes)
# 20m for timeout,
# and mem1_ssd1_v2_x16 for instance_type
tree ns-app-selectfield
# should display
ns-app-selectfield/
├── dxapp.json
├── Readme.developer.md
├── Readme.md
├── resources
├── src
│   └── ns-app-selectfield.py
└── test
    └── test.py
```

Then edit the src/ns-app-selectfield.py code look at the sekeleton first and see how it was modified.
```sh
cat $ROOT_INSTALL/scripts/ns-app-selectfield/src/ns-app-selectfield.py

cp $DIST_INSTALL/prerequisites/selectfield_template.py \
   $ROOT_INSTALL/scripts/ns-app-selectfield/src/ns-app-selectfield.py
```

Then edit the $ROOT_INSTALL/scripts/ns-app-selectfield/dxap.json and add in the runSpecs part, and fix the regionalOptions with.

```json
    "execDepends": [
      {"name": "pandas",
       "package_manager": "pip"}
    ],

  "regionalOptions": {
    "aws:eu-west-2": {
      "systemRequirements": {
        "*": {
          "instanceType": "mem1_ssd1_v2_x16"
        }
      }
    }
  }
```
Or you can run these lines to patch the dxapp.json
```bash
python $DIST_INSTALL/prerequisites/patch_app_selectfiled.py
``` 

Then "compile" the app ns-app-selectfield. It will be uploaded in /commons/ns-app/

```bash
cd $ROOT_INSTALL/scripts
ls
#ns-app-selectfiled
 
$DIST_INSTALL/prerequisites/build-ns-app-selectfield.sh ns-app-selectfiled
# reply applet-id applet-XXXXXXXXXXXXXXXXXXXXXXXXXX
```


#### ns-app-getadproxy



This app will interpret the result of a table-export csv file ouput. This app will interpret the existence of AD status in ascending of a given persons (their father or mother) to proxyfy an AD risk.

Set a ROOT_INSTALL variable
```
ROOT_INSTALL=/neurospin/brainomics/25_UM_Rap_Transition/gits/2025_amohou_wegsonrap/full_pipelines/GWAS_AD_PROXY
```

Create the template for the app.

```bash
cd $ROOT_INSTALL/scripts
dx-app-wizard --json-file $ROOT_INSTALL/prerequisites/getadproxy.json
# anser are the defaults value, 
# but Python for language, 
# 20m for timeout,
# and mem1_ssd1_v2_x16 for instance_type
tree ns-app-prolog
# should display
ns-app-prolog/
├── dxapp.json
├── Readme.developer.md
├── Readme.md
├── resources
├── src
│   └── ns-app-prolog.py
└── test
    └── test.py
```

Then edit the dxap.json and add in the runSpecs part.
```json
    "execDepends": [
      {"name": "pandas",
       "package_manager": "pip"}
    ],
```
And fix the regionalOptions with
```json
  "regionalOptions": {
    "aws:eu-west-2": {
      "systemRequirements": {
        "*": {
          "instanceType": "mem1_ssd1_v2_x16"
        }
      }
    }
  }
```


</details>

### Run the batch

This shell chain all the four steps described in the original document smoothly. All the resources are ready to be either uploaded or run in your project.


```bash
sh $DIST_INSTALL/prerequisites/batch_gwas_ad_proxy.sh
```

Please consider running each part to understand the different articulations.
