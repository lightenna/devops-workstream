
class admintools::nm_config (

) {

  # NetworkManager config
  case $operatingsystem {
    ubuntu, debian: {
      # stop NetworkManager from overwriting /etc/resolv.conf on sleep/resume
      file { 'admintools-networkmanager-resolv-protect':
        path => '/etc/NetworkManager/NetworkManager.conf',
        ensure => 'present',
        content => epp('admintools/NetworkManager.conf.epp',{}),
        owner => 'root',
        group => 'root',
        mode => '0644',
      }
    }
  }

}
