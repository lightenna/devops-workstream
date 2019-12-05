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

node 'puppetmaster', /^puppetmaster/ {
  class { '::common': }
  class { 'usertools': }
  class { '::sudo' : }
  class { 'puppetmaster': }
  class { 'puppetmaster::puppetboard':
    use_https => false,
    web_port => 18080,
  }
}
