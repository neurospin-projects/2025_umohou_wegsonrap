# Build the tools

The scripts used to elaborate the GWAS_AD_PROXI have to be prepared first

The refence for this works is from **dnanexus.github.io**: [gwas_on_adbyproxy](https://dnanexus.gitbook.io/uk-biobank-rap/science-corner/gwas-using-alzheimers-disease).

4 parts can be distinguished in the document: 
1. A notebook  (using jupyter-sparkl kernel) that would interact with RAP-central to 
   1. get information from the sql (tabular) data and 
   1. the s3 data-dictionary file
2. A WDL Workflow data language script that implement the liftover
3. A SwissArmyKnife list of commands to perform QC
4. A dx run call to the Regenie App (available from RAP-Central)


The objective is to wrap-up in a single script those 4 steps that currently run using heterogeneous interfaces.

## Build two Apps to replace Step1 above

See [howto build an app](https://academy.dnanexus.com/buildingapplets/python/python_wc) from dnanexus documentation.


### ns-app-selectfields

<details><summary>Expand for details: ns-app-selectfield</summary>


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
</details>

### ns-app-getadproxy

<details><summary>Expand for details: ns-app-getadproxy</summary>

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
