
class admintools::params (

) {

  case $::operatingsystem {
    centos, redhat, oraclelinux, fedora, ubuntu, debian: {
      $filesystem_root = '/'
      $filesystem_secure_mode = '0600'
      $hosts_target = '/etc/hosts'
      $notifier_dir = '/etc/puppetlabs/puppet/tmp'
      $admin_user = 'root'
      $admin_group = 'root'
      $admin_user_home = '/root'
    }
    windows: {
      $filesystem_root = 'C:/'
      $filesystem_secure_mode = '0640'
      $hosts_target = 'C:/Windows/System32/drivers/etc/hosts'
      $notifier_dir = 'C:/ProgramData/PuppetLabs/puppet/tmp'
      $admin_user = 'SYSTEM'
      $admin_group = 'Administrators'
      $admin_user_home = 'C:/WINDOWS'
    }
  }

}

