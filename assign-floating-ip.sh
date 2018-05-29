#!/bin/bash

# Build a devstack test machine in serverstack.
# at least 4GB RAM and 2 CPUs
# This is an m1.medium at the moment.

source common-functions.sh

function usage {
	printf "\n Assign a floating ip to an instance\n"
	printf "\nUSAGE:\n\n$0 [-h|--help] <server-name>\n"
	printf "\n\nwhere:\n"
	printf " -h | --help     : this usage page\n"
	printf " <server-name>   : the server name (e.g. devstack)\n"
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
SERVER_NAME=${1}

assert_os_vars_are_set

# See if it exists
does_instance_exist ${SERVER_NAME}
SERVER_EXISTS=$?

if [[ "xxx$SERVER_EXISTS" == "xxx0" ]]; then
	echo "$SERVER_NAME doesn't exist"
	exit 1
fi

# Now add an external IP address to it.


# Now add an external IP address to it.
# gets the ip address to ${floating_ip_address}
get_floating_ip_address

# we can only assign the IP when it's not in the build state, so loop until it's ready
while true; do
	# get server status to ${server_status}
	echo "Server name is $SERVER_NAME"
	get_server_status "${SERVER_NAME}"
	#openstack server list -c Name -c Status -f value | grep "$SERVER_NAME" | grep BUILD 2>&1 > /dev/null
	case ${server_status} in
		ACTIVE)
			break
			;;

		ERROR)
			echo "Server seems to be broken?"
			exit 1
			;;
		UNKNOWN)
			echo "Oh dear, it's in UNKNOWN?"
			exit 1
			;;
		*)
			echo "Still waiting on it"
			;;
	esac
	sleep 10
done


printf "Going to assign a floating ip to\n\n"
printf "Name: $SERVER_NAME\n"
printf "Floating ip: $floating_ip_address\n"

are_you_sure "Are you sure?"
if [[ ! -z "${_yes}" ]]; then
	echo "Assigning the IP to the server"
	which_openstack_version
	if [[ "$OS_VERSION" == "2" ]]; then
		openstack ip floating add "$floating_ip_address" "$SERVER_NAME"
	else
		openstack server add floating ip "$SERVER_NAME" "$floating_ip_address"
	fi
else
	echo "Doing nothing."
	exit 0
fi
