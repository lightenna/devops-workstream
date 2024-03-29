
class admintools::sshd (

  $force_keepalives_inboard = true,
  $force_keepalives_outboard = false,
  $max_auth_tries = 10,

) {

  case $operatingsystem {
    centos, redhat, oraclelinux, fedora, ubuntu, debian: {
      # allow for users with multiple keys in key agent
      sshd_config { "MaxAuthTries":
        ensure => present,
        value  => "${max_auth_tries}",
      }
    }
  }

  if ($force_keepalives_inboard) {
    case $operatingsystem {
      centos, redhat, oraclelinux, fedora, ubuntu, debian: {
        # configure keep alives for all incoming connections
        sshd_config { "ClientAliveInterval":
          ensure => present,
          value  => "120",
        }
        sshd_config { "ClientAliveCountMax":
          ensure => present,
          value  => "720",
        }
      }
    }
  }

  if ($force_keepalives_outboard) {
    case $operatingsystem {
      centos, redhat, oraclelinux, fedora, ubuntu, debian: {
        # configure keep alives for all incoming connections
        ssh_config { "ServerAliveInterval":
          ensure => present,
          host   => "*",
          value  => "120",
        }
        ssh_config { "ServerAliveCountMax":
          ensure => present,
          host   => "*",
          value  => "720",
        }
      }
    }
  }

}
