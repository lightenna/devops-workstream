define dodocker::userscripts (

  # class arguments
  # ---------------
  # setup defaults

  $user                 = $title,
  $group                = $title,

  # customisable constants
  $folder_name          = 'docker_control',

  # inheritted defaults
  $transfer_maintenance = $::dodocker::transfer_maintenance,

  # end of class arguments
  # ----------------------
  # begin class

) {

  $filepath_linux = "/home/${user}/${folder_name}/"
  $filepath_win = "C:\\Users\\${user}\\${folder_name}\\"
  $filepath_cygwin = "/cygdrive/c/Users/${user}/${folder_name}/"
  case $operatingsystem {
    centos, redhat, oraclelinux, fedora, ubuntu, debian: {
      $filepath = $filepath_linux
    }
    windows: {
      $filepath = $filepath_win
    }
  }

  File {
    owner  => $user,
    group  => $group,
    ensure => 'file',
  }

  # create referable file resource
  ensure_resource(usertools::safe_directory, "${filepath}", {
    user  => $user,
    group => $group,
    path  => $filepath,
  })

  if ($transfer_maintenance) {
    # transfer contents of selected directory over to target machine
    file { "dodocker-transfer-maintenance-${user}":
      ensure  => 'directory',
      source  => "puppet:///modules/dodocker/${folder_name}/maintenance",
      recurse => 'remote',
      path    => "${filepath}maintenance",
      mode    => '0750',
      require => [File[$filepath]],
    }
  }

}

