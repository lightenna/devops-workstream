define usertools::gitconfig (

  $user              = $title,
  $git_name,
  $email,
  $http_proxy        = undef,
  $credential_helper = undef,
  $push_default      = 'simple',

) {

  include '::git'

  git::config { "usertools-gitconfig-${user}-name":
    key   => 'user.name',
    value => $git_name,
    user  => $user,
  }

  git::config { "usertools-gitconfig-${user}-email":
    key   => 'user.email',
    value => $email,
    user  => $user,
  }

  if ($http_proxy != undef) {
    git::config { "usertools-gitconfig-${user}-http_proxy":
      key   => 'http.proxy',
      value => "${http_proxy}",
      user  => $user,
    }
  }

  if ($credential_helper != undef) {
    git::config { "usertools-gitconfig-${user}-credential_helper":
      key   => 'credential.helper',
      value => "${credential_helper}",
      user  => $user,
    }
  }

  if ($push_default != undef) {
    git::config { "usertools-gitconfig-${user}-push_default":
      key   => 'push.default',
      value => "${push_default}",
      user  => $user,
    }
  }

}
