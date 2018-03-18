#!/bin/bash

# This script syncs the 'devstack.*' servers that are running in serverstack, with thier public Ip addresses
# and the end of the /etc/hosts file.  Note that an existing name is deleted as needed.

_dir="$( cd "$(dirname "${BASH_SOURCE[0]}" )" && pwd)"
_script=$( basename $0 )

# bring in the common functions
source common-functions.sh


if [[ -z ${DEVSTACK_MODIFY_ETC_HOSTS} ]]; then
	echo "The env DEVSTACK_MODIFY_ETC_HOSTS isn't set so not syncing the devstack.* names"
	exit 1
fi

assert_os_vars_are_set

servers=$(openstack server list -c Name -f value | egrep "^(devstack|tinwood\-|ajkavanagh\-)")

# remove all of the devstack entries from the /etc/hosts file
echo "Deleting devstack entries from /etc/hosts"
sudo sed -i "/devstack\S*\$/d" /etc/hosts
sudo sed -i "/tinwood-\S*\$/d" /etc/hosts
sudo sed -i "/ajkavanagh-\S*\$/d" /etc/hosts
echo "Done deleting."

# now add back in each of the hosts.
for server in ${servers[@]}; do
	echo -n "Determing IP for server: $server ... "
	find_floating_ip_for $server
	if [[ "$?" == "1" ]]; then
		echo "no public IP"
	else
		echo "Adding $floating_ip"
		echo "${floating_ip}	${server}" | sudo tee -a /etc/hosts
	fi
done
