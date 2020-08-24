#!/bin/sh
command -v puppet > /dev/null && { echo "Puppet is installed, skipping" ; exit 0; }
# set up puppet repo
wget https://apt.puppetlabs.com/puppet6-release-bionic.deb
dpkg -i puppet6-release-bionic.deb
apt-get update
# reduce package download overhead
#yum -y install deltarpm
# install basic utilities
apt-get -y install wget curl unzip htop
apt-get -y install puppet-agent
# vagrant-only, linux-only hacks
mkdir -p /srv/git/github.com
chmod 0777 /srv/git/github.com
# cannot hack vagrant UID because ssh process owned by vagrant
# usermod -u 21006 vagrant && groupmod -g 31006 vagrant
