#
# site.pp
# manifest for general configuration-managed hosts
#
# Command to execute:
#     puppet apply -dvt ./manifests/site.pp --modulepath=./modules/
#

# define a single general node
node default {
  class { 'example' :
    # don't explicitly define the value of an attribute here
    # user => 'pierre',
  }
}
