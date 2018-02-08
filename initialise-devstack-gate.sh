#!/bin/bash

#set -x

# the keyfile needs to be the 2nd parameter to be able to log in.  This is probably
# id_devstack_image_rsa
if [[ ! -z "${2}" ]]; then
	DEVSTACK_SSH_IDENTITY=${2}
fi
if [[ ! -f "${DEVSTACK_SSH_IDENTITY}" ]]; then
	echo "Must set the DEVSTACK_SSH_IDENTITY or pass it as parameter 2"
	exit 1
fi

source common-functions.sh
source common-initialise.sh

## check args are okay
check_args ${1}

## copy the relevant files to the instance
REMOTE_USER=devuser
copy_files devstack-gate ${SERVER_NAME}
