define usertools::safe_symlink (

  $target,
  $link_name = $title,
  $link_base = '',
  $link_type = 'symlink',
  $user      = 'root',
  $group     = 'root',
  $ensure    = 'link',

) {

  if ($ensure == 'link') or ($ensure == 'present') {
    case $operatingsystem {
      centos, redhat, oraclelinux, fedora, ubuntu, debian: {
        $resolved_flag = $link_type ? {
          default => '-sf',
        }
        exec { "usertools-safe_symlink-${title}":
          path    => '/bin',
          user    => $user,
          group   => $group,
          command => "ln ${resolved_flag} ${target} ${link_base}${link_name}",
          creates => "${link_base}${link_name}",
          before  => [File["${title}"]],
        }
      }
      windows: {
        $resolved_flag = $link_type ? {
          'dirsym'   => '/d',
          'hard'     => '/h',
          'junction' => '/j',
          default    => '',
        }
        notify { "resolved_flag:${resolved_flag}, link_type:${link_type} ${title}": }
        exec { "usertools-safe_symlink-win-mklink-${title}":
          # command => "cmd.exe /c rmdir /Q \"${link_base}${link_name}\" & cmd.exe /c mklink ${resolved_flag} \"${link_base}${link_name}\" \"${target}\"",
          command => "C:\\Windows\\System32\\cmd.exe /c mklink ${resolved_flag} \"${link_base}${link_name}\" \"${target}
            \"",
          creates => "${link_base}${link_name}",
          before  => [File["${title}"]],
        }
      }
    }
    # create inactive file resource for dependency management
    file { "${title}":
      ensure => 'link',
      path   => "${link_base}${link_name}",
      target => "${target}",
      noop   => true,
    }
  } else {
    # create real file resource to handle removal
    file { "${title}":
      ensure => $ensure,
      path   => "${link_base}${link_name}",
      target => "${target}",
    }
  }

}