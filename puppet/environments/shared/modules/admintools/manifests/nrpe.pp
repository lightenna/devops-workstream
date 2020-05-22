
class admintools::nrpe (

  $command_list = {},
  $port = 5666,

) {

  class { 'nrpe': }

  # register with MOTD
  if defined (Class['domotd']) {
    @domotd::register { "NRPE(${port})" : }
  }
  # open port for SELinux, if in use
  if (str2bool($::selinux)) {
    if ($port != 5666) {
      selinux::port { 'admintools-nrpe-port':
        seltype  => 'inetd_child_port_t',
        port     => $port,
        protocol => 'tcp',
      }
    }
  }
  # create multiple nrpe response commands if details passed in hash
  if ($command_list != {}) {
    create_resources(nrpe::command, $command_list, {
      ensure => present
    })
  }

}
