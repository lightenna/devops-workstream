class harden (

  $lock_root               = true,
  $ssh_port                = 22,
  $ssh_service_name        = $harden::params::ssh_service_name,
  $selinux_mode            = 'enforcing',
  $password_authentication = 'no',

) inherits harden::params {

  # ensure we have SSH installed
  ensure_packages(['openssh-server'], {})

  # enable SELinux if available
  case $operatingsystem {
    centos, redhat, oraclelinux, fedora: {
      # manage SELinux
      class { 'selinux':
        mode => $selinux_mode,
        type => 'targeted',
      }
    }
    ubuntu, debian: {}
  }

  # configure ssh port(s) explicitly
  if ($ssh_port == 22) {
    sshd_config { 'harden-set-ssh-port':
      key    => 'Port',
      ensure => present,
      value  => $ssh_port,
      notify => [Service[$ssh_service_name]],
    }
  } else {
    @domotd::register { "SSH[22]": }
    sshd_config { 'harden-set-ssh-port':
      key    => 'Port',
      ensure => present,
      # also run SSH service on port 22 (local only, no firewall port open)
      value  => [22, $ssh_port],
      notify => [Service[$ssh_service_name]],
    }
    if (str2bool($::selinux)) {
      # open non-standard ports for SELinux
      selinux::port { 'harden-ssh-nonstd-seport':
        seltype  => 'ssh_port_t',
        port     => $ssh_port,
        protocol => 'tcp',
        notify   => [Service[$ssh_service_name]],
      }
    }
  }

  if ($lock_root) {
    # don't allow SSH to root
    sshd_config { 'harden-disable-root-ssh':
      key    => 'PermitRootLogin',
      ensure => present,
      value  => "no",
      notify => [Service[$ssh_service_name]],
    }
  }
  if !defined(Service[$ssh_service_name]) {
    service { "${ssh_service_name}":
      enable  => true,
      ensure  => running,
      require => [Package['openssh-server']],
    }
  }

  sshd_config { 'harden-disable-password-logins':
    key    => 'PasswordAuthentication',
    ensure => present,
    value  => $password_authentication,
    notify => [Service[$ssh_service_name]],
  }

  # don't install rkhunter, deprecated
  #class { '::rkhunter': }
  package { 'rkhunter': ensure => absent }

  # disable runs if cron_daily_run is false
  #if ($::rkhunter::cron_daily_run == false) {
  #  exec { '/usr/bin/touch /var/lock/subsys/rkhunter': }
  #}

  # some hardening can only happen at the end of the puppet run
  class { 'harden::stage_last':
    stage => 'last',
  }

}
