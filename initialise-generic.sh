#!/bin/bash

source common-functions.sh
source common-initialise.sh

## check args are okay
check_args ${1}

## copy the relevant files to the instance
copy_files generic ${SERVER_NAME}
