class swap (

  $size = 4096, # 0 to leave alone, -1 to disable
  $path = '/swapfile',

) {

  if ($size > 0) {
    # set up a swap file of the named size
    exec { 'swap-create-swapfile':
      path    => '/bin:/sbin:/usr/bin:/usr/sbin',
      command => "dd if=/dev/zero of=/swapfile count=${size} bs=1MiB && chmod 0600 /swapfile && mkswap /swapfile",
      creates => $path,
    } ->
    mount { 'swap':
      fstype   => 'swap',
      options  => 'sw',
      ensure   => 'present',
      atboot   => true,
      remounts => true,
      device   => $path,
    } ->
    exec { 'swap-turnon-swapfile':
      path    => '/bin:/sbin:/usr/bin:/usr/sbin',
      command => 'swapon -a',
    }
  }

  if ($size < 0) {
    # comment any swap lines in fstab
    exec { 'swap-commentout-fstab':
      path    => '/bin:/sbin:/usr/bin:/usr/sbin',
      command => 'sed -e \'/.*[ \t]*swap/ s/^#*/#/\' -i /etc/fstab',
    }
    # disable swap on this machine
    exec { 'swap-turnoff-swapfile':
      path    => '/bin:/sbin:/usr/bin:/usr/sbin',
      command => 'swapoff -a',
      # onlyif  => "test -e ${path}",
    } ->
    # remove swap file if present
    file { 'swap-remove-swapfile':
      ensure => 'absent',
      path   => $path,
    }
  }

}