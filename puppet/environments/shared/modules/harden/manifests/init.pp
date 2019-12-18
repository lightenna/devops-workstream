
class harden (

  $lock_root = true,
  $ssh_port = 22,
  $selinux_mode = 'enforcing',

) {

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
      key => 'Port',
      ensure => present,
      value  => $ssh_port,
      notify => [Service['sshd']],
    }
  } else {
    @domotd::register { "SSH[22]" : }
    sshd_config { 'harden-set-ssh-port':
      key => 'Port',
      ensure => present,
      # also run SSH service on port 22 (local only, no firewall port open)
      value  => [22, $ssh_port],
      notify => [Service['sshd']],
    }
    if (str2bool($::selinux)) {
      # open non-standard ports for SELinux
      selinux::port { 'harden-ssh-nonstd-seport':
        seltype  => 'ssh_port_t',
        port     => $ssh_port,
        protocol => 'tcp',
        notify => [Service['sshd']],
      }
    }
  }

  if ($lock_root) {
    # don't allow SSH to root
    sshd_config { 'harden-disable-root-ssh':
      key => 'PermitRootLogin',
      ensure => present,
      value  => "no",
      notify => [Service['sshd']],
    }
  }
  if ! defined(Service['sshd']) {
    service { 'sshd':
      enable => true,
      ensure => running,
    }
  }

  # install rkhunter
  class { '::rkhunter': }

  # some hardening can only happen at the end of the puppet run
  class { 'harden::stage_last':
    stage => 'last',
  }

}
