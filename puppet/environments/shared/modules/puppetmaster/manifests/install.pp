
class puppetmaster::install (

  $master_code_dir = '/etc/puppetlabs/code',

  # lockversion was used to restrict to 6.9.0 as 6.9.1 breaks puppetboard (18/3/2020)
  $lockversion_puppetdb = undef,

) {

  # install puppetserver
  class { '::puppetserver::repository': } ->
  class { '::puppetserver':
    config => {
      'java_args' => {
        # experimenting with smaller footprint, really should be >= 2g,2g
        'xms' => '1g',
        'xmx' => '1g',
        # support removed in JDK8
        # 'maxpermsize' => '512m',
        'tmpdir' => '/tmp',
      },
    },
  }

  # this is a bit weird as it overrides the settings in /etc/puppetlabs/puppet/puppet.conf
  puppetserver::config::puppetserver { 'puppetserver.conf/jruby-puppet/master-code-dir' :
    value => $master_code_dir,
    notify => [Service[$::puppetserver::service]],
  }

  # lock puppetdb to cope with downstream dep issues
  if ($lockversion_puppetdb != undef) {
    class { 'puppetdb::globals':
      version => $lockversion_puppetdb,
    }
    # tell yum not to update it
    case $operatingsystem {
      centos, redhat, oraclelinux, fedora: {
        ensure_packages(['yum-versionlock'], { ensure => 'present' })
        exec { 'puppetmaster-install-puppetdb-lock':
          path    => ['/bin','/sbin','/usr/bin','/usr/sbin'],
          command => "yum versionlock add puppetdb-${lockversion_puppetdb}",
          require => [Package['yum-versionlock']],
        }
      }
    }
  }

  # install puppetdb and its underlying database
  class { '::puppetdb':
    manage_firewall => false,
    java_args => {
        '-Xmx' => '512m',
        '-Xms' => '512m',
    },
    # disable_ssl => true,
  }
  class { 'puppetmaster::remove_deprecated' : }

  # create puppetserver certs
  exec { 'puppetmaster-install-puppetserver-sslsetup':
    path => ['/bin','/sbin','/usr/bin','/usr/sbin','/opt/puppetlabs/bin'],
    command => 'puppetserver ca setup',
    creates => '/etc/puppetlabs/puppet/ssl/certs/ca.pem',
    require => [Package[$::puppetserver::package]],
    notify => [Service[$::puppetserver::service]],
  }->
  # create certs and configure puppetdb jetty to use them only after puppetserver start-up
  exec { 'puppetmaster-install-puppetdb-sslsetup':
    path => ['/bin','/sbin','/usr/bin','/usr/sbin','/opt/puppetlabs/bin'],
    command => 'puppetdb ssl-setup -f',
    creates => '/etc/puppetlabs/puppetdb/ssl/public.pem',
    require => [Package[$::puppetdb::params::puppetdb_package]],
    notify => [Service[$::puppetdb::params::puppetdb_service]],
  }

  # install puppet bolt
  ensure_packages(['puppet-bolt'], { ensure => 'present' })

}

