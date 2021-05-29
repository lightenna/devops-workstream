
define usertools::bashinit (

  $user = $title,
  $group = $user,
  $home,
  $manage_bashrc = true,
  $manage_bash_profile = true,
  $manage_profile = true,

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

  # manage user's .profile file with concat
  if ($manage_profile and !defined(Concat["${home}/.profile"])) {
    concat { "${home}/.profile" :
      owner => $user,
      group => $group,
      mode => '0640',
      ensure => present,
      require => [File[$home]],
    }

    # add first lines to bashrc
    concat::fragment { "usertools-profile-${user}-base":
      target  => "${home}/.profile",
      order   => '10',
      content => @(END)
        # ~/.profile: executed by the command interpreter for login shells.
        # This file is managed by Puppet.  Do not append lines here.
        #
        # This file is not read by bash(1), if ~/.bash_profile or ~/.bash_login
        # exists.
        # see /usr/share/doc/bash/examples/startup-files for examples.
        # the files are located in the bash-doc package.

        # the default umask is set in /etc/profile; for setting the umask
        # for ssh logins, install and configure the libpam-umask package.
        #umask 022

        # if running bash
        if [ -n "$BASH_VERSION" ]; then
            # include .bashrc if it exists
            if [ -f "$HOME/.bashrc" ]; then
                . "$HOME/.bashrc"
            fi
        fi

        # set PATH so it includes user's private bin if it exists
        if [ -d "$HOME/bin" ] ; then
            PATH="$HOME/bin:$PATH"
        fi

        # set PATH so it includes user's private bin if it exists
        if [ -d "$HOME/.local/bin" ] ; then
            PATH="$HOME/.local/bin:$PATH"
        fi
        | END
    }
  }

}
