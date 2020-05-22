
class admintools::updates (
  $enable = true,
  $weekday = 'Saturday',
  $hour = 7,
) {

  case $operatingsystem {
    centos, redhat, oraclelinux, fedora: {
      # yum update at 7am on Saturday mornings (by default)
      cron { 'admintools-updates-yum':
        ensure  => $enable ? { undef => absent, false => absent, default => present, },
        command => '/usr/bin/yum update -y > /root/last-yum-update.txt & 2>&1',
        user    => 'root',
        weekday => $weekday,
        hour    => $hour,
        minute  => 0,
      }
    }
    ubuntu, debian: {
      include '::apt'
      # apt upgrade at 7am on Saturday mornings, DB update handled as part of puppet run
      cron { 'admintools-updates-apt':
        ensure  => $enable ? { undef => absent, false => absent, default => present, },
        # command => '/usr/bin/apt -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" upgrade > /root/last-apt-update.txt & 2>&1',
        command => '/usr/bin/apt-get -s -o Debug::NoLocking=true upgrade 2>&1 > /root/last-apt-update.txt &',
        user    => 'root',
        weekday => $weekday,
        hour    => $hour,
        minute  => 0,
      }
    }
  }

}
