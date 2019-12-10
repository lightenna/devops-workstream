
class devtools::languages::python (

  $pythonenv_root = '/opt/pythonenv/default',

) {

  # install default OS python
  include '::python'
  ensure_resource(anchor,'devtools-languages-python-ready',{})

  case $operatingsystem {
    centos, redhat: {
      # install SCL
      include '::scl'
      # use up-to-date Python globally
      ensure_resource(scl::collection, 'python3', {
        collection => 'rh-python36',
        enable => true,
      })
      # SCL adds /opt/rh... to path, but symlink on default path (/usr/bin) to cope with legacy hardcoded refs
      ensure_resource(usertools::safe_symlink, 'rh-python', {
        target => '/opt/rh/rh-python36/root/bin/python',
        link_name => '/usr/bin/python3',
        require => Scl::Collection['python3'],
        before => Anchor['devtools-languages-python-ready'],
      })
    }
    ubuntu, debian: {
      ensure_packages(['python3-venv'], { ensure => 'present', before => [Class['python']] })
      usertools::safe_directory { "${pythonenv_root}":
        before => [Class['python']],
      }
    }
  }

}
