class dodocker (

  $users                     = {},
  $user_defaults             = {},

  $user                      = '1000', # default service-container user
  $group                     = '1000',
  $mode                      = '0640',
  $mode_dir                  = '0750',
  $ensure                    = 'present',
  $directories               = {},
  $certs                     = {},
  $cert_defaults             = {},

  # by default, install maintenance scripts
  $transfer_maintenance      = true,
  $ensure_deps_longhorn      = true,

  # deprecated attributes
  $daemon_parameters         = undef,
  $daemon_config_path        = '/etc/docker',
  $deamon_config_fileleaf    = 'daemon.json',
  $deamon_config_file_ensure = 'present',

) {

  include '::docker'

  # avoid create_user conflict with usertools by disabling
  Docker::System_user <| |> {
    create_user => false,
  }

  # copy auth credentials if being set (typically hiera docker::registry_auth::registries)
  include 'dodocker::authspread'

  if ($ensure_deps_longhorn) {
    case $operatingsystem {
      centos, redhat, oraclelinux, fedora: {
        ensure_packages(['iscsi-initiator-utils'], { ensure => 'present' })
      }
      ubuntu, debian: {
        ensure_packages(['open-iscsi'], { ensure => 'present' })
      }
    }
  }

  # create multiple users if details passed in hash
  if ($ensure != 'absent' and $users != {}) {
    create_resources(dodocker::userscripts, $users, $user_defaults)
  }

  # create directories if passed in hash
  if ($ensure != 'absent' and $directories != {}) {
    create_resources(usertools::safe_directory, $directories, {
      user   => $user,
      group  => $group,
      mode   => $mode_dir,
      before => [Anchor['docker-ready'], Anchor['docker-directories-ready']],
    })
  }

  anchor { 'docker-directories-ready': }

  # install certs if passed in hash
  if ($ensure != 'absent' and $certs != {}) {
    create_resources(dodocker::write_cert, $certs, {
      user     => $user,
      group    => $group,
      mode     => $mode,
      mode_dir => $mode_dir,
      before   => [Anchor['docker-ready']],
      require  => [Anchor['docker-directories-ready']],
    } + $cert_defaults)
  }

  anchor { 'docker-ready': } -> Class['docker']

}
