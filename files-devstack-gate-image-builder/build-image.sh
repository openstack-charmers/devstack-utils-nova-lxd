#!/bin/bash
# calls $HOME/project-config/tools/build-image.sh with the correct parameters


_dir="$( cd "$(dirname "${BASH_SOURCE[0]}" )" && pwd)"
_script=$( basename $0 )

source "${_dir}/env-vars-for-build"

# run the script
cd $HOME/project-config && tools/build-image.sh

