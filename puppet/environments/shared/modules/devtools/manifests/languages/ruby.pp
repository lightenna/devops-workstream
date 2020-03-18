
class devtools::languages::ruby (

  $manage_gem_conf = false,
  $gem_conf_path = '/etc/opt/rh/rh-ruby25',

) {

  # install Ruby (OS-latest)
  include '::ruby'
  ensure_resource(anchor,'devtools-languages-ruby-ready',{})

  case $operatingsystem {
    centos, redhat, oraclelinux, fedora: {
      # install SCL
      include '::scl'
      # use up-to-date Ruby globally
      ensure_resource(scl::collection, 'rh-ruby25', {
        enable => true,
        before => Anchor['devtools-languages-ruby-ready'],
        require => [Class['scl']],
      })
      if ($manage_gem_conf) {
        devtools::languages::ruby::gemrcconf { "${gem_conf_path}" : }
      }
    }
  }

}
