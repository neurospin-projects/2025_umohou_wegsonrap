#!/bin/env bash

echo "install.sh will install jq (json query), wdl compiler in you ~/bin directory"
echo "      check that ~/bin is in your path"

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

jq_install() {
    # Create a bin directory if it doesn't exist
    mkdir -p ~/bin
    # Download the jq binary
    curl -L -o ~/bin/jq https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64
    # Make it executable
    chmod +x ~/bin/jq
    # Add ~/bin to PATH if not already in
    #echo 'export PATH="$HOME/bin:$PATH"' >> ~/.bashrc
    source ~/.bashrc

    echo -e "\e[32mjq installed.\e[0m"
}


dxCompiler_install() {
    VERSION=$1
    if ! command -v java &> /dev/null; then
        echo "Java is NOT installed"
        echo "Cannot install dxCompiler"
    fi

    curl -L -o ~/bin/dxCompiler.jar https://github.com/dnanexus/dxCompiler/releases/download/${VERSION}/dxCompiler-${VERSION}.jar
    echo -e '#!/bin/bash\njava -jar ~/bin/dxCompiler.jar "$@"' > ~/bin/dxCompiler
    chmod +x ~/bin/dxCompiler

    echo -e "\e[32mdxCompiler version " $VERSION " installed.\e[0m"
}

# install list
jq_install
dxCompiler_install "2.13.0"