
class puppetmaster::agent (

  $default_environment = 'production',
  $server = 'puppetmaster.localdomain',
  $run_interval = '30m',
  $run_as_service = true,

) {

  Ini_setting {
    ensure  => present,
    path    => '/etc/puppetlabs/puppet/puppet.conf',
  }
  # set the environment for the puppet agent
  ini_setting { 'puppetmaster-agent-conf-env':
    section => 'agent',
    setting => 'environment',
    value   => $default_environment,
  }
  ini_setting { 'puppetmaster-agent-conf-runinterval':
    section => 'agent',
    setting => 'runinterval',
    value   => $run_interval,
  }
  # point agent at defined master
  ini_setting { 'puppetmaster-agent-conf-server':
    section => 'agent',
    setting => 'server',
    value   => $server,
  }
  if ($run_as_service) {
    service { 'puppet': ensure => 'running', enable => 'true' }
  }


}

