#
# site.pp
# manifest for general configuration-managed hosts
#
# Command to execute:
#     puppet apply -dvt ./manifests/site.pp --modulepath=./modules/ --hiera_config=./hieradata/hiera.yaml
#

# define a single general node
node default {
  class { 'example' : }
}
