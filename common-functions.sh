# bash common functions for various common actions in the devstack scripts


## Determine if the OpenStack VARS are set to access serverstack (or anything else)

# cache the result
unset _OS_VARS

function assert_os_vars_are_set {
	local _OS_REGION_NAME
	if [[ -z "$_OS_VARS" ]]; then
		# The OS_VARS need to be set up to serverstack - let's make sure that they are
		_OS_REGION_NAME=$(env | grep OS_REGION_NAME | cut -d "=" -f 2)
		# exit if this isn't running against serverstack
		if [[ "xxx$_OS_REGION_NAME" == "xxxserverstack" ]]; then
			_OS_VARS=1
		else
			echo "OS_VARS are not set for serverstack (OS_REGION_NAME) - exiting"
			exit 1
		fi
	fi
}


## Assert that the ssh vars are set for getting keys to instances, etc.
function assert_ssh_vars_are_set {
	local _exit
	if [[ -z "$DEVSTACK_KEYPAIR_NAME" ]]; then
		echo "the \$DEVSTACK_KEYPAIR_NAME env var is not set"
		_exit=1
	fi
	if [[ -z "$DEVSTACK_SSH_IDENTITY" ]]; then
		echo "the \$DEVSTACK_SSH_IDENTITY for the private key is not set"
		_exit=1
	fi
	if [[ ! -z $_exit ]]; then
		exit 1
	fi
}



## see if we are pre-version 3.0 of the openstack client.  Some of the commands change for it.
unset OS_VERSION

function which_openstack_version {
	if [[ -z "$OS_VERSION" ]]; then
		local _version=$(openstack --version 2>&1 | awk '{print $2}')
		# take the first character of the version string
		OS_VERSION=${_version:0:1}
	fi
}


## see if an instance exists; pass the variable as the first param
# returns 1 if the instance does exist
function does_instance_exist {
	assert_os_vars_are_set
	openstack server list -c Name -f value | egrep "^${1}$" 2>&1 > /dev/null
	if [[ "$?" == "1" ]]; then
		return 0
	else
		return 1
	fi
}


## see if an image exists; pass the variable as the first param
# returns 1 if the instance does exist
function does_image_exist {
	assert_os_vars_are_set
	openstack image show $1 2>&1 > /dev/null
	if [[ "$?" == "1" ]]; then
		return 0
	else
		return 1
	fi
}


## get the public ip for an instance by name or id
# returns $? == 1 if the instance doesn't exist
function find_floating_ip_for {
	assert_os_vars_are_set
	local _addrs
	local addresses
	if [[ -z "${1}" ]]; then
		echo "Must pass a server name/id to $0"
		exit 1
	fi
	_addr_line=$(openstack server show ${1} -f shell | grep addresses)
	if [[ "$?" == "1" ]]; then
		exit 1
	fi
	# eval the shell line
	eval "$_addr_line"
	_ifs=$IFS
	IFS=', ' read -r -a _addrs <<< "$_addr_line"
	IFS=$_ifs
	if [[ "${#_addrs[@]}" == "1" ]]; then
		unset floating_ip
	fi
	# the public address is the 2nd column
	floating_ip=$(echo "${_addrs[1]}" | tr -d '"\n')
}


## wait for the server to answer on the ssh port
# $1 is the keyfile
# $2 is the options
# $3 is the username@server details
function wait_for_ssh {
	local maxConnectionAttempts=10
	local sleepSeconds=10
	echo "Checking for ssh connection ..."
	local index=1
	while (( $index <= $maxConnectionAttempts )); do
		ssh $1 echo
		case $? in
			0) echo "${index}> Ready"; break ;;
			*) echo "${index} of ${maxConnectionAttempts}> Not ready, waiting ${sleepSeconds} seconds ...";;
		esac
		sleep $sleepSeconds
		(( index+=1 ))
	done
}


## run a remote command on the server
# $1 = identity file of public key
# $2 = user to run at remote command
# $3 = server or IP to run the command on
# $4 = the command to run
function run_remote_cmd {
	local _identity_file=${1}
	local _user=${2}
	local _server=${3}
	local _cmd=${4}
	local _ssh_options="-i ${_identity_file} -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no"
	ssh ${_ssh_options} ${_user}@${_server} "'${_cmd}'"
}


## add a hostname to the /etc/hosts file; needs sudo
# the hostname is in $1 and the ip address in $2
# note that the env DEVSTACK_MODIFY_ETC_HOSTS needs to be set for this to work
function add_host_to_hosts {
	local _host_name=$1
	local _ip_address=$2
	if [[ ! -z ${DEVSTACK_MODIFY_ETC_HOSTS} ]]; then
		sudo sed -i "/${_host_name}\$/d" /etc/hosts
		echo "${_ip_address}	${_host_name}" | sudo tee -a /etc/hosts
	fi
}


## see if an key-pair exists; pass the variable as the first param
# returns 1 if the key-pair does exist
function does_keypair_exist {
	assert_os_vars_are_set
	openstack keypair list -c Name -f value | egrep "^${1}$" 2>&1 > /dev/null
	if [[ "$?" == "1" ]]; then
		return 0
	else
		return 1
	fi
}


## Returns the net_id for a searchable network name in $1
# The returned value is in the var ${net_id} and ${net_name}
function get_net_name_and_id_for_network {
	assert_os_vars_are_set
	local network_name="${1}"
	local _net
	#net_id=$(openstack network list -c ID -c Name -f value | egrep "${network_name}" | awk '{print $1}' | tr -d '\n')
	_net=$(openstack network list -c ID -c Name -f value | egrep "${network_name}")
	net_name=$(echo "$_net" | awk '{print $2}' | tr -d '\n')
	net_id=$(echo "$_net" | awk '{print $1}' | tr -d '\n')
}

## Returns the name and id of an image when passed something to grep in $1
# The last image (sorted by name) is the one returned from the grep.
# returns ${image_name} and ${image_id}
function get_image_name_and_id_from_grep {
	assert_os_vars_are_set
	local _images
	local image_grep="${1}"
	_images=$(openstack image list -c ID -c Name -f value --limit 1000| grep "$image_grep" | sort -k 2 | tail -1)
	image_name=$(echo "$_images" | awk '{print $2}' | tr -d '\n')
	image_id=$(echo "$_images" | awk '{print $1}' | tr -d '\n')
}


## Ask if you are sure. Question text is in ${1}
function are_you_sure {
	read -r -p "${1} [y/N]:" response
	response=${response,,}		# to lower case
	unset _yes
	if [[ "$response" =~ ^(yes|y)$ ]]; then
		_yes=1
	fi
}



## Get a floating IP address into ${floating_ip_address}
# exit 1 if no address could be made
function get_floating_ip_address {
	local floating_ips
	local _floating_ip
	local _floating_ip_assigned
	local _ifs
	local _cmd_list
	local _cmd_create

	unset floating_ip_address   # return value
	assert_os_vars_are_set

	which_openstack_version

	echo "Finding a free Floating IP address"
	_ifs=$IFS
	IFS='
	'
	if [[ "$OS_VERSION" == "2" ]]; then
		floating_ips=($(openstack ip floating list -c "Floating IP Address" -c "Fixed IP Address" -f value | sort -k 1))
	else
		floating_ips=($(openstack floating ip list -c "Floating IP Address" -c "Fixed IP Address" -f value | sort -k 1))
	fi
	_floating_ip=
	for floating_ip in ${floating_ips[@]}; do
		echo $floating_ip | grep None 2>&1 > /dev/null
		_floating_ip_assigned=$?
		if [[ "xxx$_floating_ip_assigned" == "xxx0" ]]; then
			_floating_ip=$(echo -n "$floating_ip" | awk '{print $1}')
			break
		fi
	done
	IFS=$_ifs

	# if we didn't find the IP then create a new one
	if [ "xxx" == "xxx$_floating_ip" ]; then
		# create a floating IP address
		echo "Didn't find one ... Creating a floating IP address"
		if [[ "$OS_VERSION" == "2" ]]; then
			_floating_ip=$(openstack ip floating create ext_net | grep "^| ip" | awk '{print $4}')
		else
			_floating_ip=$(openstack floating ip create ext_net | grep "^| floating_ip_address" | awk '{print $4}')
		fi
	fi
	if [[ "$?" != "0" ]]; then
		echo "Couldn't create a floating IP"
		exit 1
	fi
	floating_ip_address="${_floating_ip}"
}


## get the status of a server in ${1} .. returned in ${server_status}
function get_server_status {
	echo "Server is ${1}"
	assert_os_vars_are_set
	#local os_status
	echo "---Server is ${1}"
	#eval $(openstack server show "${1}" -f shell | egrep "^status")
	eval $(openstack server show "${1}" -f shell --prefix=os_ | egrep --color=never "^os_status")
	server_status=${os_status}
}
