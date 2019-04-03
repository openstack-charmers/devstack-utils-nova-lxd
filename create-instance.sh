#!/bin/bash

# Build a devstack test machine in serverstack.
# if the DONT_CONFIRM environment variable is set then the script doesn't ask for confirmation

# at least 4GB RAM and 2 CPUs
# This is an m1.medium at the moment.

#set -e

# bring in the common functions
source common-functions.sh

FLAVOR=${FLAVOR:-m1.large}
#SECURITY_GROUP=default

function usage {
	printf "\n Build a devstack related instance amd64 server image on serverstack\n"
	printf "\nUSAGE:\n\n$0 [-h|--help] <server-name> [<ubuntu-flavor>]\n"
	printf "\nUSAGE:\n\n$0 [-h|--help] <server-name> [-f <ubuntu-flavor> | -i <image-name>]\n"
	printf "\nThe script will find the latest version of the <ubuntu-flavor> (default bionic)\n"
	printf "and build an m1.large instance on serverstack and assign an virtual IP.\n"
	printf "This script only builds amd64 based machines at present.\n"
	printf "\n\nwhere:\n"
	printf " -h | --help     : this usage page\n"
	printf " <server-name>   : the server name (e.g. devstack)\n"
	printf " <ubuntu-flavor> : the flavor - e.g. bionic, etc.\n\n"
}

if [[ "$1" == "-h" || "$1" == "--help" ]]; then
	usage
	exit 0
fi

if [[ -z $1 ]]; then
	usage
	echo "ERROR! Need to supply the server name"
	exit 1
fi
DEVSTACK_NAME=${1}

if [[ -z $2  || "$2" == "-f" ]]; then
	# pick a flavour to search on
	if [[ ! -z $3 ]]; then
		#IMAGE_GREP="released.*${3}.*amd64.*\.img"
		IMAGE_GREP=".*${3}.*amd64.*\.img"
	else
		#IMAGE_GREP="released.*bionic.*amd64.*\.img"
		IMAGE_GREP=".*bionic.*amd64.*\.img"
	fi
else
	if [[ "$2" != "-i" ]]; then
		usage
		echo "ERROR! Must supply either -f <ubuntu-flavor> or -i <image-name>"
		exit 1
	fi
	if [[ -z $3 ]]; then
		usage
		echo "ERROR! If specifying image must actually provide an image name!"
		exit 1
	fi
	IMAGE_GREP="${3}"
fi

# ensure the OS_VARS are set
assert_os_vars_are_set

if [[ -z $DEVSTACK_KEYPAIR_NAME ]]; then
	echo "The env var DEVSTACK_KEYPAIR_NAME is needed to create the server."
	exit 1
fi


# See if it exists
does_instance_exist ${DEVSTACK_NAME}
DEVSTACK_EXISTS=$?

if [[ "xxx$DEVSTACK_EXISTS" == "xxx1" ]]; then
	echo "$DEVSTACK_NAME already exists; please delete if you want to recreate it"
	exit 1
fi

# check the keypair exists
does_keypair_exist ${DEVSTACK_KEYPAIR_NAME}
KEYPAIR_EXISTS=$?
if [[ "xxx${KEYPAIR_EXISTS}" == "xxx0" ]]; then
	echo "Openstack keypair '${DEVSTACK_KEYPAIR_NAME}' doesn't exist."
	exit 1
fi


# Now we need the network id so we can create the server.
# fetches to ${net_id} and ${net_name}
get_net_name_and_id_for_network "_admin_net\$"

# get the image name -- only take the last one but sort on the Name column
# function returns ${image_name} and ${image_id}
get_image_name_and_id_from_grep "${IMAGE_GREP}"

## print the summary of the variable
printf "Going to create an server with:\n\n"
printf "Name: $DEVSTACK_NAME\n"
printf "Image: $image_name\n"
printf "Image id: $image_id\n"
printf "Net name: $net_name\n"
printf "net_id: $net_id\n"
printf "Keypair: $DEVSTACK_KEYPAIR_NAME\n"
printf "Flavor: $FLAVOR\n"
#printf "Security Group: $SECURITY_GROUP\n\n"

# Ask, response is in ${response}, ${_yes} is '1' or unset if not.
if [[ -z "${DONT_CONFIRM}" ]]; then
	are_you_sure "Are you sure?"
else
	_yes=1
fi
if [[ ! -z "${_yes}" ]]; then
	echo "Creating the server ... might take a while ..."
	openstack server create --wait \
		--flavor $FLAVOR \
		--image $image_id \
		--key-name $DEVSTACK_KEYPAIR_NAME \
		--nic net-id=$net_id \
		$DEVSTACK_NAME
		#--security-group $SECURITY_GROUP --nic net-id=$net_id $DEVSTACK_NAME
	echo "Done creating"
else
	echo "Doing nothing."
	exit 0
fi

# Now add an external IP address to it.
# gets the ip address to ${floating_ip_address}
get_floating_ip_address

# Now finally assign it
echo "Assigning $floating_ip_address to $DEVSTACK_NAME"
which_openstack_version
if [[ "$OS_VERSION" == "2" ]]; then
	openstack ip floating add "$floating_ip_address" "$DEVSTACK_NAME"
else
	openstack server add floating ip "$DEVSTACK_NAME" "$floating_ip_address"
fi

# add it to the /etc/hosts file -- but only if $DEVSTACK_MODIFY_ETC_HOSTS is set
add_host_to_hosts "${DEVSTACK_NAME}" "${floating_ip_address}"
