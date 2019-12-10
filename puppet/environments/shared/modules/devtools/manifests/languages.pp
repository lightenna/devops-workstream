
class devtools::languages (

) {

  # install JRE
  include '::java'

  # install node
  include '::nodejs'

  include 'devtools::languages::python'

  # install Ruby (OS-latest)
  include '::ruby'
  ensure_resource(anchor,'devtools-languages-ruby-ready',{})

  case $operatingsystem {
    centos, redhat: {
      # install SCL
      include '::scl'
      # use up-to-date Ruby globally
      ensure_resource(scl::collection, 'rh-ruby25', {
        enable => true,
        before => Anchor['devtools-languages-ruby-ready'],
      })
    }
  }

}
