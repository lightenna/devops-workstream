
define devtools::languages::ruby::gemrcconf (

  $path = $title,
  $leaf = 'gemrc',
  $user = 'root',
  $group = 'root',
  $mode = '0755',

) {

  ensure_resource(usertools::safe_directory, "devtools-languages-ruby-gemrcconf-${title}", {
    path    => $path,
    mode    => $mode,
    user    => $user,
    group   => $group,
  })

  file { "devtools-languages-ruby-gemrcconf-${title}":
    ensure  => 'present',
    path    => "${path}/${leaf}",
    content => epp('devtools/gemrc.epp', {}),
  }

  # do gemrc config before installing gems (if anchor defined)
  Anchor <| title == 'devtools-languages-ruby-ready' |> {
    require => [File["${path}/${leaf}"]],
  }

  case $operatingsystem {
    windows: {
      # do gemrc config before running any Cygwin commands (if any defined)
      Dowindows::Cygwin::Run <| |> {
        require => [File["${path}/${leaf}"]],
      }
    }
  }

}
