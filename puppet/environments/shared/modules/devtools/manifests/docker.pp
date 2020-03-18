
class devtools::docker (

  $daemon_parameters = undef,
  $daemon_config_path = '/etc/docker/daemon.json',

) {

  include '::docker'

  if ($daemon_parameters != undef) {
    # write out configuration file
    file { 'devtools-docker-daemon-json':
      path    => "${daemon_config_path}",
      content => epp('devtools/docker/daemon.json.epp', {
        params => $daemon_parameters,
      }),
      notify  => [Service[$docker::service_name]],
      before  => [Anchor['docker-ready']],
    }
  }

  anchor { 'docker-ready': }

}
