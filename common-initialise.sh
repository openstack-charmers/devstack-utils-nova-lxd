# This file contains functions that do the initialisation for the two different devstack machines
#
# 1. devstack -- a machine for running devstack on.
# 2. devstack-gate-image-builder - a machine to build devstack-gate images

# Need to pass the type in the $1 parameter
function usage {
	local _type="${1}"
	printf "\nInitialise the ${_type} instance.\n"
	printf "\nUSAGE:\n\n${_script} [-h|--help] <server-name>\n"
	printf "\nThis script copies across the configuration files and a configure\n"
	printf "script that will configure the ${_type} for running in serverstack.\n"
	printf "\n\nwhere:\n"
	printf " -h | --help           : this usage page\n"
	printf " <server-name|IP addr> : the server name (e.g. devstack)\n\n"
	printf "The server-name should ideally be DNS resolvable from your machine.\n"
	printf "If not, then use the IP address for the build script.\n\n"
	printf "The env var DEVSTACK_SSH_IDENTITY should be set with the identity file\n"
	printf "for the keypair used to create the ${_type} server\n\n"
}

## check the argument passed.  $1 is assumed to be $1 from the script
# returns ${SERVERNAME}
function check_args {
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

	if [[ -z $DEVSTACK_SSH_IDENTITY ]]; then
		echo "ERROR: Env var DEVSTACK_SSH_IDENTITY is not set"
		exit 1
	fi
}


## copy target files to the target machine.
# $1 is the type (devstack or devstack-gate-image-builder)
# $2 is the server name
# $3 is an optional file to copy to the server files
# $DEVSTACK_SSH_IDENTITY needs to be set to access the machine
function copy_files {
	local _type="${1}"
	local SERVER_NAME="${2}"
	local optional_file="${3}"
	local to_optional_file="${4}"
	local remote_user=${REMOTE_USER:-ubuntu}

	local _ssh_options="-i $DEVSTACK_SSH_IDENTITY -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no"
	local target="configure.sh"
	local _dir="$( cd "$(dirname "${BASH_SOURCE[0]}" )" && pwd)"
	local _script=$( basename $0 )

	echo "$_dir is the source"
	# copy the files across
	wait_for_ssh "$_ssh_options $remote_user@$SERVER_NAME"
	echo "Copy files-${_type}/* to $remote_user@$SERVER_NAME:configure/."
	ssh $_ssh_options $remote_user@$SERVER_NAME 'mkdir -p configure'
	scp $_ssh_options -r files-${_type}/* $remote_user@$SERVER_NAME:configure/

	if [[ ! -z "${optional_file}" ]]; then
		scp $_ssh_options ${optional_file} $remote_user@$SERVER_NAME:configure/${to_optional_file}
	fi

	printf "Copied files to $SERVER_NAME\n"
	echo "Now ssh into ${SERVER_NAME} and run 'configure/${target}'"
}
