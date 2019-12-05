
define usertools::bashinit (

  $user = $title,
  $group = $user,
  $home,

) {

  # manage user's .bashrc file with concat
  if ! defined(Concat["${home}/.bashrc"]) {
    concat { "${home}/.bashrc" :
      owner => $user,
      group => $group,
      mode => '0640',
      ensure => present,
      require => [File[$home]],
    }

    # add first lines to bashrc
    concat::fragment { "usertools-user-${user}-base":
      target  => "${home}/.bashrc",
      order   => '10',
      content => @(END)
        # .bashrc
        # This file is managed by Puppet.  Do not append lines here.

        # Source global definitions
        if [ -f /etc/bashrc ]; then
          . /etc/bashrc
        fi
        | END
    }
  }
  
}
