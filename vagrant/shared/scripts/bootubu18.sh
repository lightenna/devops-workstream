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
