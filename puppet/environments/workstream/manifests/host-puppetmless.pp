#
# host-puppettest
# manifest for general configuration-managed host
# called directly (masterless) using:
#   puppet apply <manifest_name>
#

# define a single general node
node default {
  # include a class globally defined by the community modules
  # @todo install module with Puppet Librarian
  # include a class locally defined in the environment
  class { 'java': }
}
