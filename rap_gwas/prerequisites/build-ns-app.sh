#!/bin/bash

appname=""
runit=false

# Parse switches
while [[ "$#" -gt 0 ]]; do
    case "$1" in
        -r|--runit)
            runit=true
            shift
            ;;
        --) # End of all options
            shift
            break
            ;;
        -*)
            echo "Unknown option: $1"
            exit 1
            ;;
        *)
            break
            ;;
    esac
done

# Remaining arguments are positional
appname="$1"


# option -f force the deletion of any existing app with the same name
retval=`dx build -f $appname --destination /commons/ns-apps/`
appret=`echo "$retval" | jq -r '.id'`

echo "ns-app-selectfield is succesfully compiled and uploaded in /commons/ns-apps"

if [ "$runit" = true ]; then
  dx run --priority high $appret -ioutprefix=def_fieldname -y --watch
else
  echo "applet-id is: " $appret
fi