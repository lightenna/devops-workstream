
class puppetmaster (

  $server = $::fqdn,
  $master_code_dir = '/etc/puppetlabs/code',
  $default_environment = 'production',
  $puppetdb_https_port = 8081,
  $manage_agent = true,
  $keys = {},
  $key_defaults = {
    user => 'root',
    group => 'iac-data',
    mode => '0640',
  },

) {

  if defined(Class['domotd']) {
    # register external services ()
    @domotd::register { "Puppetserver(8140)" : }
    # register internal services []
    @domotd::register { "PuppetDB[${puppetdb_https_port}]" : }
  }

  # fetch and symlink the control repo
  class { 'puppetmaster::control_repo':
    before => [Anchor['puppetmaster-puppet-begin']],
  }

  anchor { 'puppetmaster-puppet-begin' : }

  # install components
  if ($manage_agent) {
    class { 'puppetmaster::agent':
      default_environment => $default_environment,
      server              => $server,
    }
  }
  class { 'puppetmaster::install' :
    master_code_dir => $master_code_dir,
    require => [Anchor['puppetmaster-puppet-begin']],
  }

  Ini_setting {
    ensure  => present,
    path    => '/etc/puppetlabs/puppet/puppet.conf',
    require => [Class['puppetmaster::install']],
  }
  # set the codedir for puppet (e.g. lookup) calls on the puppet master, although master-code-dir also set in /etc/puppetlabs/puppetserver/conf.d/puppetserver.conf by ::puppermaster module
  ini_setting { 'puppetmaster-conf-master-codedir':
    section => 'master',
    setting => 'codedir',
    value   => $master_code_dir,
  }
  # set the environment for the puppet master
  ini_setting { 'puppetmaster-conf-master-default-env':
    section => 'master',
    setting => 'environment',
    value   => $default_environment,
  }
  # store reports in puppetdb
  ini_setting { 'puppetmaster-conf-master-reports':
    section => 'master',
    setting => 'reports',
    value   => 'puppetdb',
  }

  # configure the Puppet master to use Puppetdb
  class { '::puppetdb::master::config':
    strict_validation => false,
    puppetdb_port => $puppetdb_https_port,
    # don't specify localhost, because cert matches FQDN only
    # puppetdb_server => 'localhost',
    # don't connect over HTTP, puppetserver no longer supports that
    # puppetdb_disable_ssl => true,
  }
  # install eyaml plugin for puppetserver
  class { '::puppetserver::hiera::eyaml':
    require => Class['puppetserver::install'],
  }

  # install keys if set
  if ($keys != {}) {
    create_resources(usertools::write_keypair, $keys, $key_defaults)
  }

  # define puppetmaster as local machine (for command line puppet)
  host { 'puppetmaster-host-puppetlocal':
    name => 'puppet',
    ensure => 'present',
    ip => '127.0.0.1',
    host_aliases => $::fqdn,
    target => '/etc/hosts',
    before => [Anchor['puppetmaster-puppet-begin']],
  }

  # use anchor pattern to ensure containment of selected resources
  anchor { 'puppetmaster-puppet-complete' :
    require => [Anchor['puppetmaster-puppet-begin']],
  }

}

