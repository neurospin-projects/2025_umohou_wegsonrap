#!/bin/bash
# Script to install the code that wilk be run on RAP.

# utils
red()    { echo -e "\e[31m$*\e[0m"; }
green()  { echo -e "\e[32m$*\e[0m"; }
yellow() { echo -e "\e[33m$*\e[0m"; }

if [ "${DIST_INSTALL+x}" ]; then
  green "Using installation code $DIST_INSTALL" 
else
  red "DIST_INSTALL is not set"
fi
if [ "${ROOT_INSTALL+x}" ]; then
  green "Preparing code to exectute on RAP in $ROOT_INSTALL"
else
  red "ROOT_INSTALL is not set"
fi

#
green "Step1"
green "====="
#############
green "Creating ns-app-selectfield"
mkdir -p $ROOT_INSTALL/scripts
cd $ROOT_INSTALL/scripts
rm -rf $ROOT_INSTALL/scripts/ns-app-selectfield

## Invoke dx-app-wizard with sidecar ns-app-selectfield.json to specify output input
dx-app-wizard --json-file $DIST_INSTALL/prerequisites/ns-app-selectfield.json << EOF1 > /dev/null
ns-app-selectfield
0.0.1
20m
Python
y
y
mem1_ssd1_v2_x16
EOF1

green "   ns-app-selectfiled created from wizard with specified input/ouput"

## patch the code .py
cp $DIST_INSTALL/prerequisites/ns-app-selectfield_template.py \
    $ROOT_INSTALL/scripts/ns-app-selectfield/src/ns-app-selectfield.py
green "   src/ns-app-selectfield.py  code patched"
## patch the dxApp.json
$DIST_INSTALL/prerequisites/patch_app.py ns-app-selectfield
green "   dxApp.json  patched from ns-app-slectfield.json"


#############
green "Creating ns-app-getadproxy"
mkdir -p $ROOT_INSTALL/scripts
cd $ROOT_INSTALL/scripts
rm -rf $ROOT_INSTALL/scripts/ns-app-getadproxy

## Invoke dx-app-wizard with sidecar ns-app-selectfield.json to specify output input
dx-app-wizard --json-file $DIST_INSTALL/prerequisites/ns-app-getadproxy.json << EOF2 > /dev/null
ns-app-getadproxy
0.0.1
20m
Python
y
y
mem1_ssd1_v2_x16
EOF2
green "   ns-app-getadproxy created from wizard with specified input/ouput"

## patch the code .py
cp $DIST_INSTALL/prerequisites/ns-app-getadproxy_template.py \
    $ROOT_INSTALL/scripts/ns-app-getadproxy/src/ns-app-getadproxy.py
green "   src/ns-app-getadproxy.py  code patched"
## patch the dxApp.json
$DIST_INSTALL/prerequisites/patch_app.py ns-app-getadproxy
green "   dxApp.json  patched from ns-app-getadproxy.json"



green "Step2-3"
green "======="
#############
green "Fetching resources."
$DIST_INSTALL/prerequisites/fetch_resources.sh -i $ROOT_INSTALL

