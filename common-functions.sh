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

	unset floating_ip_address   # return value
	assert_os_vars_are_set

	echo "Finding a free Floating IP address"
	_ifs=IFS
	IFS='
	'
	floating_ips=($(openstack floating ip list -c "Floating IP Address" -c "Fixed IP Address" -f value | sort -k 1))
	_floating_ip=
	for floating_ip in ${floating_ips[@]}; do
		echo $floating_ip | grep None 2>&1 > /dev/null
		_floating_ip_assigned=$?
		if [[ "xxx$_floating_ip_assigned" == "xxx0" ]]; then
			_floating_ip=$(echo -n "$floating_ip" | awk '{print $1}')
			break
		fi
	done
	IFS=_ifs

	# if we didn't find the IP then create a new one
	if [ "xxx" == "xxx$_floating_ip" ]; then
		# create a floating IP address
		echo "Didn't find one ... Creating a floating IP address"
		_floating_ip=$(openstack floating ip create ext_net | grep "^| ip" | awk '{print $4}')
	fi
	if [[ "$?" != "0" ]]; then
		echo "Couldn't create a floating IP"
		exit 1
	fi
	floating_ip_address="${_floating_ip}"
}


## get the status of a server in ${1} .. returned in ${server_status}
function get_server_status  {
	assert_os_vars_are_set
	local status
	eval $(openstack server show ${1} -f shell | egrep "^status")
	server_status=${status}
}
