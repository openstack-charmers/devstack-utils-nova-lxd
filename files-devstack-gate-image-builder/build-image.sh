#!/bin/bash
# calls $HOME/project-config/tools/build-image.sh with the correct parameters


_dir="$( cd "$(dirname "${BASH_SOURCE[0]}" )" && pwd)"
_script=$( basename $0 )

source "${_dir}/env-vars-for-build"
source "${_dir}/proxy-vars"

# run the script
cd $HOME/project-config && tools/build-image.sh

