#!/bin/bash

# Idempotently configure the devstack machine
# I run on the devstack machine in the 'configure' directory
# I've been put there, along with my files, by this same script.

set -ex

_dir="$( cd "$(dirname "${BASH_SOURCE[0]}" )" && pwd)"
_script=$( basename $0 )

IFACE="ens3"


# first fix up resolv.conf so we can get some software
echo "nameserver 10.5.0.2" | sudo tee /etc/resolv.conf
# fix interfaces.d/ens3.cfg so that dns-nameservers is 10.5.0.2
if ! grep "10.5.0.2" /etc/network/interfaces.d/ens3.cfg; then
	echo "dns-nameservers 10.5.0.2" | sudo tee -a /etc/network/interfaces.d/ens3.cfg
fi
# fix /etc/dhcp/dhclient.conf so that it doesn't get overwritten
sudo sed -i 's|127.0.0.1|10.5.0.2|g' /etc/dhcp/dhclient.conf

# and fix our name to 'devstack-gate'
echo "devstack-gate" | sudo tee /etc/hostname
sudo hostname devstack-gate

echo "jenkins ALL=(ALL) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/jenkins
sudo chmod 440 /etc/sudoers.d/jenkins

# fix the ubuntu user so that it has a /bin/bash path
sudo sed -i 's|/home/devuser:|/home/devuser:/bin/bash|g' /etc/passwd

# install some useful stuff
sudo apt update
sudo apt upgrade -y
sudo apt autoremove -y
sudo apt install -y vim-nox silversearcher-ag byobu less bridge-utils python3-yaml
# Note, the devstack-gate initialisation HUNG on python3-yaml setup, so this is just to
# get around that issue.


# now install the files into their various places:
# dot.gitconfig
if [[ ! -f "$HOME/.gitconfig" ]]; then
	echo "Copying dot.gitconfig"
	cp "${_dir}/dot.gitconfig" "$HOME/.gitconfig"
fi
## add the dot.gitconfig-jenkins to /home/jenkins/.gitconfig if the they are not present
if ! grep "squid.internal" /home/jenkins/.gitconfig; then
	cat "${_dir}/dot.gitconfig-jenkins" | sudo tee -a /home/jenkins/.gitconfig
fi

# install the no-proxy.sh bin file
mkdir -p $HOME/bin
cp "${_dir}/no-proxy.sh" "$HOME/bin/no-proxy-sh"

# etc-environment
# first we need to change 'localaddress' to the local IP address in the no_proxy lines
_ip_address=$(ip a | grep 10.5 | awk '{print $2}' | tr "/" "\n" | head -1 | tr -d "\n")
sed -i s/localaddress/$_ip_address/g "$_dir/etc-environment"
sed -i s/localaddress/$_ip_address/g "$_dir/proxy-vars"

# also fix the cannot resolve hostname issue
if ! grep "$_ip_address" /etc/hosts; then
	echo "$_ip_address	devstack-gate" | sudo tee -a /etc/hosts
fi

# add the etc-environment lines to /etc/environment if the line length is less
# than that of our etc-environment
_lines_ours=$(cat ${_dir}/etc-environment | wc -l)
_lines_theirs=$(cat /etc/environment | wc -l)
if (( $_lines_ours > $_lines_theirs )); then
	echo "Updating /etc/environment"
	sudo DIR=$_dir su -p - root -c 'cat "$DIR/etc-environment" >> /etc/environment'
fi

# "lock" /etc/hosts, /etc/hostname and /etc/resolv.conf to stop dhclient fiddling with them
# I've had endless problems trying to get it to work properly and this is a ghetto fix
# to lock the files into place
sudo chattr +i /etc/hosts
sudo chattr +i /etc/hostname
sudo chattr +i /etc/resolv.conf

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

# Fix the http pipelining for apt through squid.internal
echo 'Acquire::http::Pipeline-Depth "0";' | sudo tee /etc/apt/apt.conf.d/90localsettings
# force IPV4 for debian as well
echo 'Acquire::ForceIPv4 "true";' | sudo tee /etc/apt/apt.conf.d/90force-ipv4
# and place the 90proxy-settings file into /etc/apt/apt/conf.d
sudo cp ${_dir}/90proxy-settings /etc/apt/apt.conf.d/.

# copy the jenkins user related scripts

sudo -u jenkins mkdir /home/jenkins/bin
sudo cp ${_dir}/setup-job.sh /home/jenkins/bin
sudo chown jenkins.jenkins /home/jenkins/bin/setup-job.sh
sudo cp ${_dir}/no-proxy.sh /home/jenkins/bin
sudo chown jenkins.jenkins /home/jenkins/bin/no-proxy.sh
sudo cp ${_dir}/devstack-vars /home/jenkins/bin
sudo chown jenkins.jenkins /home/jenkins/bin/devstack-vars
sudo cp ${_dir}/proxy-vars /home/jenkins/bin
sudo chown jenkins.jenkins /home/jenkins/bin/proxy-vars
sudo cp ${_dir}/run-legacy-tempest-dsvm-lxd-ovs.sh /home/jenkins/bin
sudo chown jenkins.jenkins /home/jenkins/bin/run-legacy-tempest-dsvm-lxd-ovs.sh
sudo mkdir -p /home/jenkins/.byobu
sudo cp ${_dir}/keybindings.tmx /home/jenkins/.byobu/keybindings.tmux
sudo chown -R jenkins.jenkins /home/jenkins/.byobu

# add sourcing the vars to the .profile for jenkins
sudo -u jenkins sed -i "/devstack-vars\$/d" /home/jenkins/.profile
echo "source \$HOME/bin/devstack-vars" | sudo -u jenkins tee -a /home/jenkins/.profile

# copy the authorized keys over so we can login as jenkins
sudo cp /home/devuser/.ssh/authorized_keys /home/jenkins/.ssh/authorized_keys
sudo chown jenkins.jenkins /home/jenkins/.ssh/authorized_keys

# finally run the setup-job.sh script as the jenkins user
sudo -u jenkins HOME=/home/jenkins /home/jenkins/bin/setup-job.sh

echo "Configure Done."
