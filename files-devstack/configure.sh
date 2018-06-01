#!/bin/bash

# Idempotently configure the devstack machine
# I run on the devstack machine in the 'configure' directory
# I've been put there, along with my files, by this same script.

set -ex

_dir="$( cd "$(dirname "${BASH_SOURCE[0]}" )" && pwd)"
_script=$( basename $0 )

# set byobu ctrl-a feature, assuming byobu is present
BYOBU_CTRL_A=$(which byobu-ctrl-a)
if [[ "$?" == "0" ]]; then
	${BYOBU_CTRL_A} screen
fi

# install some useful stuff
sudo apt update
sudo apt upgrade -y
sudo apt autoremove -y
sudo apt install -y python-pip silversearcher-ag libpython-dev libpython3-dev

# now install the files into their various places:
# dot.gitconfig
if [[ ! -f "$HOME/.gitconfig" ]]; then
	echo "Copying dot.gitconfig"
	cp "${_dir}/dot.gitconfig" "$HOME/.gitconfig"
fi

# etc-environment
# first we need to change 'localaddress' to the local IP address in the no_proxy lines
_ip_address=$(ip a | grep 10.5 | awk '{print $2}' | tr "/" "\n" | head -1 | tr -d "\n")
sed -i s/localaddress/$_ip_address/g "$_dir/etc-environment"
# add the etc-environment lines to /etc/environment if the line length is less
# than that of our etc-environment
_lines_ours=$(cat etc-environment | wc -l)
_lines_theirs=$(cat /etc/environment | wc -l)
if (( $_lines_ours > $_lines_theirs )); then
	echo "Updating /etc/environment"
	#sudo -Eu root bash -c '$_cmd'
	sudo DIR=$_dir su -p - root -c 'cat "$DIR/etc-environment" >> /etc/environment'
fi

# etc-systemd-system.conf
# also append the two lines to /etc/systemd/system.conf
# - we'll assume that if they don't exist in the file that we need to add them.
_ifs=$IFS
IFS='
'
_lines=$(cat "$_dir/etc-systemd-system.conf")
for l in $_lines; do
	echo "line"
	echo $l
	found=$(grep -x "$l" /etc/systemd/system.conf || true)
	echo $found
	if [[ -z $found ]]; then
		echo "Line not present -- adding"
		sudo LINE=${l} su -p - root -c 'echo "$LINE" >> /etc/systemd/system.conf'
	fi
done
IFS=$_ifs

# grab, but don't install the pylxd repository (we may need to mangle it before installation)
if [[ ! -d $HOME/pylxd ]]; then
	git clone https://github.com/lxc/pylxd.git $HOME/pylxd
fi

# grab, but don't install the devstack repository
if [[ ! -d $HOME/devstack ]]; then
	git clone https://github.com/openstack-dev/devstack $HOME/devstack
fi

# put a get_pip.py - e.g. zesty has the following error with STACK
# curl: (35) error:140770FC:SSL routines:SSL23_GET_SERVER_HELLO:unknown protocol
cp $_dir/get-pip.py $HOME/devstack/files/get-pip.py
[[ -r $HOME/devstack/files/get-pip.py.downloaded ]] && rm $HOME/devstack/files/get-pip.py.downloaded

# devstack-local.conf
# finally put dev stack local into the correct place - overwrite the existing file if necessary
cp $_dir/devstack-local.conf $HOME/devstack/local.conf

