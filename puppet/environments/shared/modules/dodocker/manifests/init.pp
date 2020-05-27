
class dodocker (

  $users                = {},
  $user_defaults        = {},

  $daemon_parameters = undef,
  $daemon_config_path = '/etc/docker',
  $deamon_config_fileleaf = 'daemon.json',
  $mode = '0755',
  $user = 'root',
  $group = 'root',
  $ensure = 'present',
  $directories = {},

  # by default, install maintenance scripts
  $transfer_maintenance = true,
  $ensure_deps_longhorn = true,

) {

  include '::docker'

  # copy auth credentials if being set (typically hiera docker::registry_auth::registries)
  include 'dodocker::authspread'

  if ($ensure_deps_longhorn) {
    case $operatingsystem {
      centos, redhat, oraclelinux, fedora: {
        ensure_packages(['iscsi-initiator-utils'], { ensure => 'present'})
      }
      ubuntu, debian: {
        ensure_packages(['open-iscsi'], { ensure => 'present' })
      }
    }
  }

  # create multiple users if details passed in hash
  if ($users != {}) {
    create_resources(dodocker::userscripts, $users, $user_defaults)
  }

  if ($daemon_parameters != undef) {
    # ensure directory exists
    ensure_resource(usertools::safe_directory, "dodocker-conf-path", {
      path    => "${daemon_config_path}",
      mode    => $mode,
      user    => $user,
      group   => $group,
    })
    # write out configuration file
    file { 'dodocker-daemon-json':
      path    => "${daemon_config_path}/${deamon_config_fileleaf}",
      content => epp('dodocker/daemon.json.epp', {
        params => $daemon_parameters,
      }),
      owner   => $user,
      group   => $group,
      require => [File["${daemon_config_path}"]],
      notify  => [Service[$docker::service_name]],
      before  => [Anchor['docker-ready']],
    }
  }

  if ($ensure != 'absent' and $directories != {}) {
    create_resources(usertools::safe_directory, $directories, {
      user    => $user,
      group   => $group,
      before  => [Anchor['docker-ready']],
    })
  }

  anchor { 'docker-ready': }

}
