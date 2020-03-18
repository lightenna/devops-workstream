
define devtools::languages::python::pipconf (

  $path = $title,
  $leaf = 'pip.conf',
  $user = 'root',
  $group = 'root',
  $mode = '0755',

) {

  ensure_resource(usertools::safe_directory, "devtools-languages-python-pipconf-${title}", {
    path    => $path,
    mode    => $mode,
    user    => $user,
    group   => $group,
  })

  file { "devtools-languages-python-pipconf-${title}":
    ensure  => 'present',
    path    => "${path}/${leaf}",
    content => epp('devtools/pip.conf.epp', {}),
    before => Anchor['devtools-languages-python-ready'],
  }

}
