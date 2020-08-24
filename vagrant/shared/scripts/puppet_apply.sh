#!/bin/sh
/opt/puppetlabs/bin/puppet apply -dvt --hiera_config=/tmp/vagrant-manualpuppet/environments/prod/hiera.yaml --modulepath=/tmp/vagrant-manualpuppet/modules:/tmp/vagrant-manualpuppet/environments/shared/modules:/tmp/vagrant-manualpuppet/environments/prod/modules /tmp/vagrant-manualpuppet/environments/prod/manifests/
