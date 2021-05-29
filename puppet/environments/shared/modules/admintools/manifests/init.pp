class admintools (

  $yumrepos               = {},
  $yumrepo_defaults       = {
    enabled  => 1,
    gpgcheck => true,
  },
  $packages               = {},
  $package_defaults       = {},
  $notifier_dir           = $admintools::params::notifier_dir,
  $known_hosts            = {},
  $known_host_defaults    = {},

  $machine_notes          = undef,
  $machine_notes_filename = 'machine_notes.txt',
  $admin_user             = $admintools::params::admin_user,
  $admin_group            = $admintools::params::admin_group,
  $admin_user_home        = $admintools::params::admin_user_home,
  $filesystem_root        = $admintools::params::filesystem_root,
  $filesystem_secure_mode = $admintools::params::filesystem_secure_mode,

  $keys                   = {},
  $key_defaults           = {},

) inherits admintools::params {

  contain 'admintools::sshd'

  # set up update schedule
  contain 'admintools::updates'

  # manage /etc/hosts
  contain 'admintools::hosts'

  # automatically resize partitions/volumes if necessary
  contain 'admintools::autoresize'

  # set up git SSH rules/known hosts if required
  include 'admintools::git_ssh'

  # process pre-run deps
  class { 'admintools::stage_first':
    stage => 'first',
  }

  # additions by OS
  case $::operatingsystem {
    centos, redhat, oraclelinux, fedora: {
    }
    ubuntu, debian: {
      contain 'admintools::os::ubuntu'
    }
  }

  # additional repos
  case $operatingsystem {
    centos, redhat, oraclelinux, fedora: {
      Yumrepo {
        before => [Anchor['admintools-packman-ready']],
      }
      # install yumrepos if defined
      if ($yumrepos != {}) {
        create_resources(yumrepo, $yumrepos, $yumrepo_defaults)
      }
    }
  }

  # common anchor for ensuring that the package manager is ready
  anchor { 'admintools-packman-ready': }
  Package {
    require => [Anchor['admintools-packman-ready']],
  }

  case $operatingsystem {
    centos, redhat, oraclelinux, fedora, ubuntu, debian: {
      # typically installed on all machines, so minimal set of secure tools
      include '::git'
      # install basic tools
      ensure_packages(['lynx', 'iftop', 'htop', 'iotop', 'curl', 'sysstat', 'mlocate'], { ensure => 'present' } + $package_defaults)
    }
  }

  case $operatingsystem {
    centos, redhat, oraclelinux, fedora: {
      # redundant, included by postfix module
      # ensure_packages(['mailx'], { ensure => 'present' })
      ensure_packages(['perl-libwww-perl', 'perl-LWP-Protocol-https', 'perl-Time-HiRes', 'perl-Crypt-SSLeay'], { ensure
      => 'present' } + $package_defaults)
      # install serverspec test deps
      ensure_packages(['nmap-ncat'], { ensure => 'present' } + $package_defaults)
      # install PAM deps to remove `PAM unable to dlopen(/usr/lib64/security/pam_fprintd.so)` error
      ensure_packages(['fprintd-pam'], { ensure => 'present' } + $package_defaults)
    }
    ubuntu, debian: {
      ensure_packages(['mailutils', 'libwww-perl'], { ensure => 'present' } + $package_defaults)
      # install serverspec test deps
      ensure_packages(['netcat'], { ensure => 'present' } + $package_defaults)
    }
  }

  # install named packages
  if ($packages != {}) {
    create_resources(package, $packages, {
      ensure => 'present'
    } + $package_defaults)
  }

  # install keys if set
  if ($keys != {}) {
    # set fallback key_defaults here to 1) create platform-specific defaults and 2) allow hiera key_defaults
    $fallback_key_defaults = {
      user  => $admin_user,
      group => $admin_group,
      mode  => $filesystem_secure_mode,
      path  => "${filesystem_root}srv/keys",
    }
    create_resources(usertools::write_keypair, $keys, $fallback_key_defaults + $key_defaults)
  }

  # make sure notifier directory exists
  if ($notifier_dir != undef) {
    ensure_resource(usertools::safe_directory, "${notifier_dir}", {
      user  => $admin_user,
      group => $admin_group,
    })
  }

  # write out machine notes if any set
  if ($machine_notes != undef) {
    file { 'admintools-admin_user-machine_notes':
      path    => "${admin_user_home}/${machine_notes_filename}",
      owner   => $admin_user,
      group   => $admin_group,
      content => $machine_notes,
    }
  }

}
