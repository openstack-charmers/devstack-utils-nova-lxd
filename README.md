# Creating the devstack test VM on Serverstack

Also lots of information from: https://gist.github.com/ChrisMacNaughton/29165b7b930f9aa08f3ba20abf617087

There are two scripts:

1. build-devstack-machine.sh
2. configure-devstack-machine.sh

The former builds an m1.large machine, configures the networking and assigns an external IP address.
The second one does the bulk of configuration so that it works.

The pylxd library needs to be installed (and possibly modified) - see below.

pylxd: Needs a change to the idna required (<2.16.0) for the setup.py:

        'requests!=2.8.0,>=2.5.2,<2.16.0',

and then:

	pip install -e .

in the pylxd directory.


	cd devstack

Need this for 17.04 as the SSL has been updated and no longer supports the cert at bootstrap.pypa.io

	PIP_GET_PIP_URL=http://bootstrap.pypa.io/get-pip.py ./stack.sh

To run tempest with a working stack:

	cd /opt/stack/tempest tox
