define usertools::user (

  $user                  = $title,
  $group                 = $user,
  $group_primary         = $group,
  $uid                   = undef,
  $gid                   = undef,
  $shell                 = '/bin/bash',
  $password              = undef,
  $managehome            = true,
  $managehome_ssh        = true,
  $manage_command_prompt = true,
  $manage_logout         = true,
  $home                  = undef,
  $home_mode             = '0700',
  $home_dir_root         = '/home',
  $comment               = '',
  $ensure                = 'present',
  $groups                = [],
  $keys                  = {},
  $symlinks              = {},
  $directories           = {},
  $colouring             = {},
  $bashadditions         = {},
  $default_bashaddition  = {},

  $git_email             = undef,
  $git_name              = undef,
  $git_http_proxy        = undef,
  $git_credential_helper = undef,
  $git_push_default      = undef,

  $ssh_auth_key          = '',
  $ssh_auth_key_type     = 'ssh-rsa',
  $colouring_chophost    = '',

  # @todo remove, only introduced for compatibility with common::mkuser
  $create_group          = undef,

) {

  # get path for user's home directory
  if ($home == undef) {
    if ($user == 'root') {
      $home_resolved = '/root'
    } else {
      $home_resolved = "${home_dir_root}/${user}"
    }
  } else {
    $home_resolved = "${home}"
  }

  ensure_resource('user', $user, {
    ensure     => $ensure,
    uid        => $uid,
    gid        => $gid,
    shell      => $shell,
    groups     => $groups,
    password   => $password,
    managehome => $managehome,
    home       => $home_resolved,
    comment    => $comment,
  })

  # create group if it's the same as the user
  if ($group == $user) {
    ensure_resource('group', $group, {
      ensure => $ensure,
      gid    => $gid,
    })
  }

  if ($managehome) {
    usertools::safe_directory { "usertools-user-${user}-home":
      ensure  => $ensure,
      path    => $home_resolved,
      mode    => $home_mode,
      user    => $user,
      group   => $group,
      require => User[$user],
    }
  }
  if ($managehome_ssh) {
    usertools::safe_directory { "usertools-user-${user}-home-dotssh":
      ensure  => $ensure,
      path    => "${home_resolved}/.ssh",
      mode    => $home_mode,
      user    => $user,
      group   => $group,
      require => [File["${home_resolved}"]],
    }
    if ($ssh_auth_key != '') {
      Ssh_authorized_key <| title == "${name}" |> {
        require => [File["${home_resolved}/.ssh"]],
      }
    }
  }

  if ($ensure != 'absent' and $group_primary != $group) {
    # set user's primary group
    exec { "usertools-user-group-setprimary-${user}-${group_primary}":
      path    => '/usr/sbin',
      command => "usermod -g ${group_primary} ${user}",
      require => User[$user],
    }
  }

  # e.g. github symlink
  if ($ensure != 'absent' and $managehome and $symlinks != {}) {
    create_resources(usertools::safe_symlink, $symlinks, {
      link_base => "${home_resolved}/",
      user      => $user,
      group     => $group,
      require   => User[$user],
    })
  }

  # e.g. srv directory
  if ($ensure != 'absent' and $directories != {}) {
    create_resources(usertools::safe_directory, $directories, {
      user    => $user,
      group   => $group,
      require => User[$user],
    })
  }

  if ($ensure != 'absent' and $managehome) {
    # initialise bash for later concats
    usertools::bashinit { "${user}":
      group   => "${group}",
      home    => "${home_resolved}",
      require => [File["${home_resolved}"]],
    }

    # apply additions if set
    if ($bashadditions != {}) {
      $bashadditions.each |$key, $value| {
        usertools::bashaddition { "usertools-user-bashadd-${user}-${key}":
          content => $value['content'],
          target  => $value['target'],
          user    => $user,
          home    => $home_resolved,
          require => [File["${home_resolved}"]],
        }
      }
    }

    if ($manage_command_prompt) {
      # add command-line colouring [all users]
      ensure_resource(usertools::colouring, "${user}", $colouring + {
        home     => $home_resolved,
        chophost => $colouring_chophost,
      })
    }

    if ($manage_logout) {
      # add session timeout [all users]
      usertools::autologout { "${user}":
        home => "${home_resolved}",
      }
    }
  }

  if ($ensure != 'absent' and $git_email != undef) {
    usertools::gitconfig { "${user}":
      git_name          => $git_name,
      email             => $git_email,
      http_proxy        => $git_http_proxy,
      credential_helper => $git_credential_helper,
      push_default      => $git_push_default,
      require           => User[$user],
    }
  }

  # create keys if set
  # warning: use with care, each key name must be globally unique
  if ($ensure != 'absent' and $managehome_ssh and $keys != {}) {
    create_resources(usertools::userkey, $keys, {
      user    => $user,
      group   => $group,
      home    => $home_resolved,
      require => User[$user],
    })
  }

  if ($ensure != 'absent' and $ssh_auth_key != '') {
    ssh_authorized_key { $name:
      ensure => present,
      user   => $user,
      key    => $ssh_auth_key,
      type   => $ssh_auth_key_type,
    }
  }

}
