define usertools::bashaddition (

  # $title set but not much used
  $content,
  $user,
  $home,
  $target = '.bashrc',

) {

  # add line(s) to target file
  concat::fragment { "usertools-bashaddition-${user}-${title}":
    target  => "${home}/${target}",
    order   => '40',
    content => $content,
  }

}
