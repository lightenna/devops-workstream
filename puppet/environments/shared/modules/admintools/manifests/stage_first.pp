
class admintools::stage_first (

) {

  case $operatingsystem {
    centos, redhat, oraclelinux, fedora: {
    }
    ubuntu, debian: {
      exec { 'admintools-stage_first-apt-update':
        path => ['/bin','/sbin','/usr/bin','/usr/sbin'],
        command => 'dpkg-reconfigure debconf -fnoninteractive && apt update && apt-get update',
      }
    }
  }

}
