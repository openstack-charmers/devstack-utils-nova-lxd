#!/bin/bash

# This script needs as the $1 param the public key that will be used to build the image
#set -x

key_file=${2}

source common-functions.sh
source common-initialise.sh

## check args are okay
check_args ${1}

if [[ -z "${key_file}" ]]; then
	echo "Must must a keyfile to be copied to the server"
	exit 1
fi

if [[ ! -f "${key_file}" ]]; then
	echo "The ${key_file} actually has to exist!"
fi

## copy the relevant files to the instance
copy_files devstack-gate-image-builder ${SERVER_NAME} ${key_file} builder-key.pub
