#
# site.pp
# manifest for general configuration-managed hosts
#
# Command to execute:
#     puppet apply -dvt ./manifests/site.pp --modulepath=./modules/ --hiera_config=./hiera.yaml
#

node default {
  class { 'example' : }
}

node remprov {
  class { 'example' : }
}
