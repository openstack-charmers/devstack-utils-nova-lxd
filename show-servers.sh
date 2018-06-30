#!/bin/bash

## Just list the servers that are on the currently defined stack


SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do # resolve $SOURCE until the file is no longer a symlink
  DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
  SOURCE="$(readlink "$SOURCE")"
  [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE" # if $SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
done
_dir="$( cd "$(dirname "${SOURCE[0]}" )" && pwd)"
_script=$( basename $0 )

# bring in the common functions
source ${_dir}/common-functions.sh

# main script starts here
assert_ssh_vars_are_set
assert_os_vars_are_set

openstack server list -c Name -c Status -c Networks
