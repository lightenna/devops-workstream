class dodocker::csf (

  $postd_path     = '/etc/csf/post.d',
  $user           = 'root',
  $group          = 'root',

  # currently using simpler post.d script with net=host
  $postd_template = 'docker.jsherz.sh.epp',
  # template variables
  $docker_int     = 'docker0',
  $docker_network = '172.17.0.0/16',

) {

  # ensure post.d directory exists
  usertools::safe_directory { 'dodocker-csf-postd':
    path  => "${postd_path}",
    user  => $user,
    group => $group,
    mode  => '0700',
  }

  # hack around broken escaping (puppet interpolates \$i)
  $i = '$i'
  # add custom rule to hunt for CSF additions in /etc/csf/post.d
  csf::rule { 'dodocker-csf-postd-wildscript':
    target  => '/etc/csf/csfpost.sh',
    order   => 50,
    require => [File["${postd_path}"]],
    notify  => [Service['csf']],
    content => @("END")
      # look for scripts in ${postd_path}
      if [ -d ${postd_path} ]; then
        for i in ${postd_path}/*.sh; do
          if [ -r $i ]; then
            . $i
          fi
        done
        unset i
      fi
      | END
  }

  # copy in script to manage docker entries on CSF refresh
  file { 'dodocker-csf-postd-dockersh':
    path    => "${postd_path}/docker.sh",
    content => epp("dodocker/csf/post.d/${postd_template}", {
      docker_int     => $docker_int,
      docker_network => $docker_network,
    }),
    mode    => '0700',
    owner   => $user,
    group   => $user,
    require => [File["${postd_path}"]],
    notify  => [Service['csf']],
  }

}