#!/bin/bash

# Idempotently configure the devstack machine
# I run on the devstack machine in the 'configure' directory
# I've been put there, along with my files, by this same script.

set -ex

_dir="$( cd "$(dirname "${BASH_SOURCE[0]}" )" && pwd)"
_script=$( basename $0 )

# install some useful stuff
sudo apt update
sudo apt upgrade -y
sudo apt autoremove -y
sudo apt install -y python-pip silversearcher-ag libpython-dev libpython3-dev qemu-utils debootstrap kpartx python3-openstackclient python-diskimage-builder


# now install the files into their various places:
# dot.gitconfig
if [[ ! -f "$HOME/.gitconfig" ]]; then
	echo "Copying dot.gitconfig"
	cp "${_dir}/dot.gitconfig" "$HOME/.gitconfig"
fi

# install the no-proxy.sh bin file
mkdir -p $HOME/bin
cp "${_dir}/no-proxy.sh" "$HOME/bin/no-proxy-sh"

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
_ifs=IFS
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

function install_git_repo {
	local repo=${1}
	local directory=${2}
	local tag=${3}
	local _pwd
	if [[ ! -d "$HOME/${directory}" ]]; then
		git clone "https://github.com/${repo}" $HOME/${directory}
		if [[ ! -z "$tag" ]]; then
			_pwd=`pwd`
			cd $HOME/${directory}
			git checkout $tag -b $tag
			cd ${_pwd}
		fi
	fi
}

# grab, but don't install the devstack repository
install_git_repo openstack-dev/devstack devstack

# grab, but don't install the project-config repository
install_git_repo openstack-infra/project-config project-config

# grab, but don't install (yet) the diskimage-builder
#install_git_repo openstack/diskimage-builder diskimage-builder tags/2.7.2
install_git_repo openstack/diskimage-builder diskimage-builder

# and now install diskimage builder (as root)
cd $HOME/diskimage-builder && sudo pip install .
