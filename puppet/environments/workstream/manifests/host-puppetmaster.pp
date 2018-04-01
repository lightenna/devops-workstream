#
# host-puppetmless
# manifest for general configuration-managed host
# called directly (masterless) using:
#   puppet apply <manifest_name>
#

# define a single puppetmless node
node default {
  # include a class globally defined by the community modules
  # @todo install module with Puppet Librarian
  # include a class locally defined in the environment
  class { 'java': }

  # @todo add 'puppet' to /etc/hosts
  # @todo install puppetDB
  # @todo sort certs
}
