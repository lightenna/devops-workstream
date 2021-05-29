class admintools::nm_config (

  $user                    = 'root',
  $group                   = 'root',
  $file_mode               = '0644',

  $protect_resolv_on_sleep = true,
  $manage_ethernet_devices = true,
  $manage_wifi_devices     = true,

) {

  File {
    owner => $user,
    group => $group,
    mode  => $file_mode,
  }

  # NetworkManager config
  case $operatingsystem {
    ubuntu, debian: {
      if ($protect_resolv_on_sleep) {
        # stop NetworkManager from overwriting /etc/resolv.conf on sleep/resume
        file { 'admintools-networkmanager-resolv-protect':
          path    => '/etc/NetworkManager/NetworkManager.conf',
          ensure  => 'present',
          content => epp('admintools/NetworkManager.conf.epp', {}),
        }
      }
      if ($manage_ethernet_devices or $manage_wifi_devices) {
        # tell NetworkManager to exclude certain types of device from the 'unmanaged' list
        file { 'admintools-networkmanager-manage-unmanaged':
          path    => '/usr/lib/NetworkManager/conf.d/10-globally-managed-devices.conf',
          ensure  => 'present',
          content => epp('admintools/10-globally-managed-devices.conf.epp', {
            manage_ethernet_devices => $manage_ethernet_devices,
            manage_wifi_devices     => $manage_wifi_devices,
          }),
        }
      }
    }
  }


}
