class dodocker::authspread (

  $kubelet_path         = '/var/lib/kubelet',
  $user                 = 'root',
  $group                = 'root',
  $user_home            = '/root',
  $docker_settings_path = '.docker',
  $docker_settings_leaf = "config.json",
  $docker_settings_alternate = ".dockercfg",

) {

  # install required command-line tools
  ensure_packages(['jq'], { ensure => 'present' })

  # listen for creation of source settings
  # - doesn't work because 'docker' class uses an exec login rather than creating a file
  #File <| path == "${user_home}/${docker_settings_path}/${docker_settings_leaf}" |> {
  #  notify => [Exec['dodocker-authspread-copy']],
  #}

  # wait for all the registry_auths to complete before spreading
  Docker::Registry <| |> {
    before => [Exec['dodocker-authspread-copy']],
  }

  # ensure that the required folder exists
  ensure_resource(usertools::safe_directory, "${kubelet_path}", {
    user  => $user,
    group => $group,
    mode  => '0755',
  })

  # when source file detected, copy to target and secure
  exec { 'dodocker-authspread-copy':
    path    => ['/bin', '/sbin', '/usr/bin', '/usr/sbin'],
    user    => $user,
    group   => $group,
    onlyif  => "test -e ${user_home}/${docker_settings_path}/${docker_settings_leaf}",
    require => [File["${kubelet_path}"]],
    command => @("END")
        cat ${user_home}/${docker_settings_path}/${docker_settings_leaf} \
           | jq .auths \
           > ${kubelet_path}/${docker_settings_alternate} \
        && chown ${user}:${group} ${kubelet_path}/${docker_settings_alternate} \
        && chmod 0640 ${kubelet_path}/${docker_settings_alternate}
        | END
  }

}