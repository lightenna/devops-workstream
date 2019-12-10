
# define a general class
class local::general (
  $pignore_list = [],
  $fignore_list = [],
) {
  class { '::common': }
  class { 'usertools': }
  class { 'harden': }
  # allow sudo
  class { '::sudo' : }
  # message of the day
  class { 'domotd' : }
  class { 'swap': }
  # set up firewall control
  class { '::csf': }
  # ensure lfd running
  service { 'lfd':
    ensure     => 'running',
    enable     => true,
    require    => [Class['csf']],
  }
  # lfd process ignore lists
  if defined (csf::pignore) {
    csf::pignore { $pignore_list:
      notify => Service['lfd'],
    }
  }
  if defined (csf::fignore) {
    csf::fignore { $fignore_list:
      notify => Service['lfd'],
    }
  }
  # test on all boxes (if devtools::test::script_name named in hiera)
  class { 'devtools::test' : }
  # only for vagrant
  if ($::fqdn =~ /.vagrant/) {
    notify { 'Dev server build: using vagrant config': }
  } else {
    # omit some config from vagrant (dev) boxes
  }
}
