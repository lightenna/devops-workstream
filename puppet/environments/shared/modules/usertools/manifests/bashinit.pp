
define usertools::bashinit (

  $user = $title,
  $group = $user,
  $home,
  $manage_bashrc = true,
  $manage_bash_profile = true,

) {

  # manage user's .bashrc file with concat
  if ($manage_bashrc and !defined(Concat["${home}/.bashrc"])) {
    concat { "${home}/.bashrc" :
      owner => $user,
      group => $group,
      mode => '0640',
      ensure => present,
      require => [File[$home]],
    }

    # add first lines to bashrc
    concat::fragment { "usertools-bashrc-${user}-base":
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

  # manage user's .bash_profile file with concat
  if ($manage_bash_profile and !defined(Concat["${home}/.bash_profile"])) {
    concat { "${home}/.bash_profile" :
      owner => $user,
      group => $group,
      mode => '0640',
      ensure => present,
      require => [File[$home]],
    }

    # add first lines to bashrc
    concat::fragment { "usertools-bash_profile-${user}-base":
      target  => "${home}/.bash_profile",
      order   => '10',
      content => @(END)
        # .bash_profile
        # This file is managed by Puppet.  Do not append lines here.

        # Get the aliases and functions
        if [ -f ~/.bashrc ]; then
                . ~/.bashrc
        fi

        # User specific environment and startup programs
        PATH=$PATH:$HOME/.local/bin:$HOME/bin
        export PATH
        | END
    }
  }

}
