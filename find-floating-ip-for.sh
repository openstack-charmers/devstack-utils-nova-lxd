#!/bin/bash

# $1 is the name or id of the instance to search the IP address for

#set -x

# bring in the common functions
source common-functions.sh


function usage {
	printf "\nFind the floating IP address for an instance by name or id\n"
	printf "\nUSAGE:\n\n$0 [-h|--help] <instance name|instance id>]\n"
	printf "\n\nwhere:\n"
	printf " -h | --help                 : this usage page\n"
	printf " <instance name|instance id> : the image part to search for\n\n"
}

if [[ -z "$1" || "$1" == "-h" || "$1" == "--help" ]]; then
	usage
	exit 0
fi

# ensure the OS_VARS are set
assert_os_vars_are_set

# get the image name -- only take the last one but sort on the Name column
# function returns ${image_name} and ${image_id}

find_floating_ip_for "${1}"

if [[ "$?" == "0" ]]; then
	printf "${floating_ip}\n"
else
	printf "Not found\n"
fi
