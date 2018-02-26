# Run enough of the gate test to allow debugging.
# remember to add debugging statements to the target code as needed.

source $HOME/bin/proxy-vars

export PYTHONUNBUFFERED=true

export DEVSTACK_GATE_TEMPEST=1
export DEVSTACK_GATE_TEMPEST_FULL=1
export DEVSTACK_GATE_NEUTRON=1
export DEVSTACK_GATE_VIRT_DRIVER="lxd"
export PROJECTS="openstack/nova-lxd $PROJECTS"

cat << 'EOF' > "/tmp/dg-local.conf"
[[local|localrc]]
enable_plugin nova-lxd git://git.openstack.org/openstack/nova-lxd

EOF

# keep localrc to be able to set some vars in pre_test hook
export KEEP_LOCALRC=1

function pre_test_hook {
	source $HOME/workspace-cache/openstack/nova-lxd/contrib/ci/pre_test_hook.sh
}
export -f pre_test_hook

function post_test_hook {
	source $HOME/workspace-cache/openstack/nova-lxd/contrib/ci/post_test_hook.sh
}
export -f post_test_hook

export DEVSTACK_GATE_SETTINGS=$HOME/workspace-cache/openstack/nova-lxd/devstack/tempest-dsvm-lxd-rc

cd $HOME/workspace/testing

cp devstack-gate/devstack-vm-gate-wrap.sh ./safe-devstack-vm-gate-wrap.sh
./safe-devstack-vm-gate-wrap.sh 2>&1 | tee $HOME/workspace/testing/test-run.log.txt

