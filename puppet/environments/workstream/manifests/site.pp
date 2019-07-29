#
# site.pp
# manifest for general configuration-managed hosts
#

# define a single general node
node default {
  # include a class globally defined by the community modules
  # @todo install global module
  # include a class locally defined in the environment
  class { 'example': }
}
