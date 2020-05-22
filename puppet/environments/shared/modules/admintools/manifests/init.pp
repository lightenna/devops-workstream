
class admintools (

  $yumrepos = {},
  $yumrepo_defaults = {
    enabled => 1,
    gpgcheck => true,
  },
  $packages = [],
  $notifier_dir = '/etc/puppetlabs/puppet/tmp',
  $github_public_key = 'AAAAB3NzaC1yc2EAAAABIwAAAQEAq2A7hRGmdnm9tUDbO9IDSwBK6TbQa+PXYPCPy6rbTrTtw7PHkccKrpp0yVhp5HdEIcKr6pLlVDBfOLX9QUsyCOV0wzfjIJNlGEYsdlLJizHhbn2mUjvSAHQqZETYP81eFzLQNnPHt4EVVUh7VfDESU84KezmD5QlWpXLmvU31/yMf+Se8xhHTvKSCZIFImWwoG6mbUoWf9nzpIoaSjB+weqqUUmpaaasXVal72J+UX2B+2RPW3RcT0eOzQgqlJL3RKrTJvdsjE3JEAvGq3lGHSZXy28G3skua2SmVi/w4yCE6gbODqnTWlg7+wC604ydGXA8VJiS5ap43JXiUFFAaQ==',
  $github_over_https = false,

  $machine_notes = undef,
  $machine_notes_filename = 'machine_notes.txt',
  $admin_user = 'root',
  $admin_group = 'root',
  $admin_user_home = '/root',
  $keys = {},
  $key_defaults = {
    user  => $admin_user,
    group => $admin_group,
    mode  => '0640',
    path  => '/srv/keys',
  },

) {

  contain 'admintools::sshd'

  # set up update schedule
  contain 'admintools::updates'

  # manage /etc/hosts
  contain 'admintools::hosts'

  # process pre-run deps
  class { 'admintools::stage_first':
    stage => 'first',
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
  anchor { 'admintools-packman-ready' : }
  Package {
    require => [Anchor['admintools-packman-ready']],
  }

  # typically installed on all machines, so minimal set of secure tools
  include '::git'

  # accept Github's key
  sshkey { 'github.com':
    type   => 'ssh-rsa',
    key    => $github_public_key,
  }

  # set up SSH to go over HTTPS (443)
  if ($github_over_https) {
    # indirect requests to github.com via ssh.github.com
    sshkey { 'ssh.github.com':
      type   => 'ssh-rsa',
      key    => $github_public_key,
    }
    ssh_config { "admintools-github-over-https-hostname":
      ensure    => present,
      host      => "github.com",
      key       => "Hostname",
      value     => "ssh.github.com",
    }
    ssh_config { "admintools-github-over-https-port":
      ensure    => present,
      host      => "github.com",
      key       => "Port",
      value     => "443",
    }
  }

  # install basic tools
  ensure_packages(['lynx', 'iftop', 'htop', 'curl'], { ensure => 'present' })

  # install CSF deps
  ensure_packages(['net-tools'], { ensure => 'present' })

  case $operatingsystem {
    centos, redhat, oraclelinux, fedora: {
      # redundant, included by postfix module
      # ensure_packages(['mailx'], { ensure => 'present' })
      ensure_packages(['perl-libwww-perl', 'perl-LWP-Protocol-https', 'perl-Time-HiRes', 'perl-Crypt-SSLeay'], { ensure => 'present' })
      # install CSF deps
      ensure_packages(['bind-utils'], { ensure => 'present' })
      # install serverspec test deps
      ensure_packages(['nmap-ncat'], { ensure => 'present' })
    }
    ubuntu, debian: {
      ensure_packages(['mailutils'], { ensure => 'present' })
      ensure_packages(['libwww-perl'], { ensure => 'present' })
      # install CSF deps
      ensure_packages(['bind9-host'], { ensure => 'present' })
      # install serverspec test deps
      ensure_packages(['netcat'], { ensure => 'present' })
    }
  }

  # install named packages
  if ($packages != []) {
    ensure_packages($packages, { ensure => 'present' })
  }

  # install keys if set
  if ($keys != {}) {
    create_resources(usertools::write_keypair, $keys, $key_defaults)
  }

  # make sure notifier directory exists
  ensure_resource(usertools::safe_directory, "${notifier_dir}", {})

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
