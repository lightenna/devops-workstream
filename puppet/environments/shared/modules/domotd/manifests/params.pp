class domotd::params {

  $use_dynamics = false
  $issue = '/etc/issue'
  $issue_template = '/etc/issue.template'
  $notifier_dir = '/etc/puppetlabs/puppet/tmp'
  $tcp_in_list = ''
  $tcp_in_hash = { value => '' }

  case $operatingsystem {
    centos, redhat, oraclelinux, fedora: {
      $motd = '/etc/motd'
      $motd_template = '/etc/motd.template'
      $rc_local_target = '/etc/rc.d/rc.local'
      $update_motd_target = undef
    }
    ubuntu, debian: {
      $motd = "${notifier_dir}/domotd-motd"
      $motd_template = "${notifier_dir}/domotd-motd.template"
      $rc_local_target = '/etc/rc.local'
      $update_motd_target = '/etc/update-motd.d/15-devopera-motd'
    }
  }

}
