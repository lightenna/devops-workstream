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
