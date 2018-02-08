#!/bin/bash


_dir="$( cd "$(dirname "${BASH_SOURCE[0]}" )" && pwd)"
_script=$( basename $0 )

source "${_dir}/undercloud-novarc-v3"

set -x
$_dir/no-proxy.sh openstack image create devstack-gate \
	--file "$HOME/project-config/devstack-gate.qcow2" \
	--disk-format=qcow2 \
	--container-format=bare

# also for serverstack we need to set the hypervisor_type property to 'qemu' as
# otherwise the image will break on serverstack.
$_dir/no-proxy.sh openstack image set devstack-gate --architecture x86_64 --property hypervisor_type=qemu
