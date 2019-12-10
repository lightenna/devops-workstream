
class swap (
  $size = 4096
) {
  # set up 4GB swap file
  exec { 'swap-create-swapfile':
    path    => '/bin:/sbin:/usr/bin:/usr/sbin',
    command => "dd if=/dev/zero of=/swapfile count=${size} bs=1MiB && chmod 0600 /swapfile && mkswap /swapfile",
    creates => '/swapfile',
  }->
  mount { 'swap':
    fstype   => 'swap',
    options  => 'sw',
    ensure   => 'present',
    atboot   => true,
    remounts => true,
    device   => '/swapfile',
  }->
  exec { 'swap-turnon-swapfile':
    path    => '/bin:/sbin:/usr/bin:/usr/sbin',
    command => 'swapon -a',
  }
}