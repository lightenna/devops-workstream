
class devtools::languages::go (

  $version = '1.13.3', # 22/10/2019
  $go_path = '/usr/local/go',

) {

  class { 'golang':
    version   => "${version}",
    workspace => "${go_path}",
  }

  exec { 'devtools-languages-go-install-dep':
    path => ['/bin','/sbin','/usr/bin','/usr/sbin', "${go_path}/bin"],
    command => "bash -c \"GOPATH=${go_path} GOBIN=${go_path}/bin curl https://raw.githubusercontent.com/golang/dep/master/install.sh | sh\"",
    creates => '/usr/local/go/bin/dep',
    environment => ["GOPATH=${go_path}"],
    require => [Class['golang']],
  }

}
