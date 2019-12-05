
define usertools::gitconfig (

  $user = $title,
  $git_name,
  $git_email,

) {

  include '::git'

  git::config { "usertools-gitconfig-${user}-name" :
    key   => 'user.name',
    value => $git_name,
    user  => $user,
  }

  git::config { "usertools-gitconfig-${user}-email" :
    key   => 'user.email',
    value => $git_email,
    user  => $user,
  }

}
