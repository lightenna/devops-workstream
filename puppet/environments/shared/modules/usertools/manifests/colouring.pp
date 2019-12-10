define usertools::colouring (

  $user      = $title,
  $home,
  $host_part = '\h',
  $shared    = true,
  $chophost  = '',

) {

  if ($shared) {
    # created shared file and include for all users
    if !defined(File['/etc/bash_colouring']) {
      # create colouring script in /etc/bash_colouring only once
      file { '/etc/bash_colouring':
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        content => template('usertools/bash_colouring.erb'),
        mode    => '0644',
      }
    }
    concat::fragment { "usertools-colouring-bashrc-${user}":
      target  => "${home}/.bashrc",
      order   => '20',
      content => @(END)
          # add command-line colouring if present
          if [ -f /etc/bash_colouring ]; then
            source /etc/bash_colouring
          fi
          | END
    }
  }
  else {
    # created individual colouring scripts in .bashrc
    concat::fragment { "usertools-colouring-bashrc-${user}":
      target  => "${home}/.bashrc",
      order   => '20',
      content => template('usertools/bash_colouring.erb'),
    }
  }
}
