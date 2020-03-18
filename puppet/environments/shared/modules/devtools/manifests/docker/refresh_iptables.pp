
class devtools::docker::refresh_iptables (

  $notifier_dir = '/etc/puppetlabs/puppet/tmp',
  $notifier_file = 'devtools-docker-refresh_iptables-restart',

) {

  # hack to restart docker so it can pick up the new iptables config after CSF install
  exec { 'devtools-docker-refresh-iptables-restart' :
    path => ['/bin','/sbin','/usr/bin','/usr/sbin'],
    command => "service docker restart && touch ${notifier_dir}/${notifier_file}",
    unless => "test -e ${notifier_dir}/${notifier_file}",
    require => [File["${notifier_dir}"], Service['docker']],
    before => [Anchor['docker-ready']],
  }

}
