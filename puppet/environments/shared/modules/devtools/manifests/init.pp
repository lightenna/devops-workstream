
class devtools (

) {

  include '::git'
  include 'devtools::languages'

  ensure_packages(['wget', 'jq', 'ca-certificates'], { ensure => 'present' })

  # install bolt
  ensure_packages(['puppet-bolt'], { ensure => 'present' })

  # install shell additions
  ensure_packages(['bash-completion'], { ensure => 'present' })

  # install C/C++ build tools
  ensure_packages(['make', 'gcc'], { ensure => 'present' })
  case $operatingsystem {
    centos, redhat: {
      ensure_packages(['gcc-c++'], { ensure => 'present' })
    }
    ubuntu, debian: {
      ensure_packages(['g++'], { ensure => 'present' })
      # install rdkafka deps (Ubuntu only)
      ensure_packages(['liblz4-dev', 'musl-dev', 'libsasl2-dev', 'libssl-dev'], { ensure => 'present' })
    }
  }

}
