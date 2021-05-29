
class harden::params {

  # enable SELinux if available
  case $operatingsystem {
    centos, redhat, oraclelinux, fedora: {
      $ssh_service_name = 'sshd'
    }
    ubuntu, debian: {
      $ssh_service_name = 'ssh'
    }
  }

}
