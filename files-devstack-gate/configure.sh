#!/bin/bash

# Idempotently configure the devstack machine
# I run on the devstack machine in the 'configure' directory
# I've been put there, along with my files, by this same script.

set -ex

_dir="$( cd "$(dirname "${BASH_SOURCE[0]}" )" && pwd)"
_script=$( basename $0 )


# first fix up resolv.conf so we can get some software
echo "nameserver 10.5.0.2" | sudo tee /etc/resolv.conf

# and fix our name to 'devstack-gate'
echo "devstack-gate" | sudo tee /etc/hostname

echo "jenkins ALL=(ALL) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/jenkins

# fix the ubuntu user so that it has a /bin/bash path
sudo sed -i 's|/home/devuser:|/home/devuser:/bin/bash|g' /etc/passwd

# install some useful stuff
sudo apt update
sudo apt upgrade -y
sudo apt autoremove -y
sudo apt install -y vim-nox silversearcher-ag byobu less


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

# copy the jenkins user related scripts

sudo -u jenkins mkdir /home/jenkins/bin
sudo cp ${_dir}/setup-job.sh /home/jenkins/bin
sudo chown jenkins.jenkins /home/jenkins/bin/setup-job.sh
