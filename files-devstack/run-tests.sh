#!/bin/bash

# Run the tempest tests using the regex provided in
# ~/nova-lxd/tempest/tempest-dsvm-lxd-rc

echo "Ensure that you've done do-stack.sh!"

source "${HOME}/nova-lxd/devstack/tempest-dsvm-lxd-rc"
cd /opt/stack/tempest
tox -eall -- "${DEVSTACK_GATE_TEMPEST_REGEX}"
