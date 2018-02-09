#!/bin/bash

## create, configure, and build a devstack instance using the latest xenial nightly.

# This function relies on the keypair name being in the env variables:
# DEVSTACK_KEYPAIR_NAME  -- the name of the same keypair as below for all instances.
# DEVSTACK_SSH_IDENTITY  -- the private key file
# DEVSTACK_MODIFY_ETC_HOSTS=1 -- this will add the instance_name to /etc/hosts for easy login

_dir="$( cd "$(dirname "${BASH_SOURCE[0]}" )" && pwd)"
_script=$( basename $0 )

# bring in the common functions
source common-functions.sh

INSTANCE_NAME=${INSTANCE_NAME:-devstack}
IMAGE_FLAVOR=${IMAGE_FLAVOR:-xenial}


function usage {
	printf "\nBuild and configure a devstack image\n"
	printf "\nUSAGE:\n\n$0 [-h|--help]\n"
	printf "\nThis script builds and configures a devstack instance that is ready to log\n"
	printf "log into and perform nova-lxd tests.\n"
	printf "This script only builds amd64 based machines at present.\n"
	printf "\n\nwhere:\n"
	printf " -h | --help     : this usage page\n"
}


if [[ "$1" == "-h" || "$1" == "--help" ]]; then
	exit 0
fi


function check_existing_assets {
	# check if the image builder exists
	does_instance_exist ${INSTANCE_NAME}
	if [[ "$?" == "1" ]]; then
		are_you_sure "The ${INSTANCE_NAME} exists; delete it and continue (y) or exit (N)"
		if [[ "$_yes" == "1" ]]; then
			openstack server delete --wait ${INSTANCE_NAME}
		else
			echo "Not continuing."
			exit 0
		fi
	fi
}




# main script starts here
echo -n "Checking ssh and OS_ vars ..."
assert_ssh_vars_are_set
assert_os_vars_are_set
echo " done."

echo "Checking to see if instance exists ..."
check_existing_assets
echo "Done."

# Phase 1 - create the instance -- this also adds to /etc/hosts if configured to do so.
echo "Creating the server and applying an IP address ..."
DONT_CONFIRM="true" $_dir/create-instance.sh ${INSTANCE_NAME} -f ${IMAGE_FLAVOR}
echo "Done creating instance."

echo "Doing the initalisation to prepare the instance ..."
# get the IP address of the next stage  to $floating_ip
find_floating_ip_for ${INSTANCE_NAME}
$_dir/initialise-devstack.sh $floating_ip
echo "Done initialising image."

# Phase 2 - initialise the instance to build the image
run_remote_cmd $DEVSTACK_SSH_IDENTITY ubuntu ${floating_ip} configure/configure.sh

echo "All done!"
