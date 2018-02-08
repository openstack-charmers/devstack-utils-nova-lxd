#!/bin/bash

source common-functions.sh

get_server_status $1
echo "Status is '${server_status}'"
