#!/bin/env python
import json
import os
import sys

if len(sys.argv) > 1:
    appname = sys.argv[1]
else:
    print("patch_app got no parameter.")
    print("Syntax patch_app <ns-app-name>")
    exit(1)

if appname not in ['ns-app-selectfield', 'ns-app-getadproxy']:
    print("patch_app got no valid parameter.")
    print("Syntax patch_app <ns-app-name>")
    print("     ns-app-name>in ['ns-app-selectfield', 'ns-app-getadproxy']")
    exit(1)

# assume ROOT and DIST INSTALL
root=os.getenv('ROOT_INSTALL')
dist=os.getenv('DIST_INSTALL')

# set filenames
appfn = os.path.join(root, 'scripts', appname, 
                     'dxapp.json')
patchfn = os.path.join(dist, 'prerequisites', f'{appname}.json')

# open and read
dxapp = json.load(open(appfn))
patch = json.load(open(patchfn))

# Patch
dxapp['runSpec']['execDepends'] = patch['runSpec']['execDepends']
dxapp['regionalOptions'] = patch['regionalOptions']

# Write
json.dump(dxapp, open(appfn, 'w'), indent=4)

# exit
