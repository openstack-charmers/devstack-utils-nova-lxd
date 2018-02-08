#!/bin/bash

# Find an image for a grep in $1 and $2
# If $1 is -f then look for the flavor of the image (released.*${2}.*amd64),
# otherwise just search for the image

#set -e

# bring in the common functions
source common-functions.sh


function usage {
	printf "\nFind an image based on the passed parameter(s)\n"
	printf "\nUSAGE:\n\n$0 [-h|--help] [-f] [<image-grep>]\n"
	printf "\nThe script will find the latest version of the <ubuntu-flavor> (default xenial)\n"
	printf "if -f is passed to the script and with the optional name, otherwise it will\n"
	printf "just grep for the image and find the LAST one."
	printf "\n\nwhere:\n"
	printf " -h | --help     : this usage page\n"
	printf " -f | --flavor   : do a specific search for an ubuntu image type (e.g. xenial, trusty)"
	printf " <image-grep>    : the image part to search for\n\n"
}

if [[ "$1" == "-h" || "$1" == "--help" ]]; then
	usage
	exit 0
fi

if [[ -z $1  || "$1" == "-f"  || "$1" == "--flavor" ]]; then
	# pick a flavour to search on
	if [[ ! -z $2 ]]; then
		IMAGE_GREP="released.*${2}.*amd64"
	else
		IMAGE_GREP="released.*xenial.*amd64"
	fi
else
	IMAGE_GREP="${1}"
fi

# ensure the OS_VARS are set
assert_os_vars_are_set

# get the image name -- only take the last one but sort on the Name column
# function returns ${image_name} and ${image_id}
get_image_name_and_id_from_grep "${IMAGE_GREP}"

## print the summary of the variable
printf "Found the following image:\n\n"
printf "Image: $image_name\n"
printf "Image id: $image_id\n"
