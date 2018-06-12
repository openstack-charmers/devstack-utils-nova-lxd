#!/bin/bash

# Just run the stack command.
# Before running this, you ought to ensure that local.conf in /devstack/ has
# the right configuration.  e.g.

# [[local|localrc]]
# enable_plugin nova-lxd https://github.com/openstack/nova-lxd refs/changes/49/574349/1

# will target a particular version/ref on nova-lxd so that it can be tested.

cd "${HOME}/devstack"
./stack.sh

