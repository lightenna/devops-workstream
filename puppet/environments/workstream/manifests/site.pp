#
# site.pp
# manifest for general configuration-managed hosts
#

# define a general default for unmatched nodes
node default {
  # include a class locally defined in the environment
  class { 'example': }
}

# match all hosts beginning 'puppetmaster...'
node /^puppetmaster/ {
  # include classes from the community modules
  class { '::common': }
  # temporarily disable sudo becuase might be causing mid-run issue
  # class { '::sudo' : }
  # include shared modules
  class { 'usertools': }
  class { 'puppetmaster': }
  class { 'puppetmaster::puppetboard':
    use_https => false,
    web_port => 18080,
  }
}

# match the master teaching puppetmaster with an empty catalogue to avoid over-puppetting it
node 'puppetmaster.training.azure-dns.lightenna.com' {
  notify { 'No resources were managed' : }
}
