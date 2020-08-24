#!/bin/sh
command -v puppet > /dev/null && { echo "Puppet is installed, skipping" ; exit 0; }
# set up puppet repo
yum -y install epel-release
rpm -Uvh https://yum.puppetlabs.com/puppet6/puppet6-release-el-7.noarch.rpm
# reduce package download overhead
yum -y install deltarpm
# install basic utilities
yum -y install wget curl unzip htop
# install semanage for SELinux
yum -y install policycoreutils-python
yum -y update
yum -y install puppet-agent
# vagrant-only, linux-only hacks
mkdir -p /srv/git/github.com
chmod 0777 /srv/git/github.com
# cannot hack vagrant UID because ssh process owned by vagrant
# usermod -u 21006 vagrant && groupmod -g 31006 vagrant
