class devtools::puppet (

) {

  include 'devtools::languages::ruby'
  # install required gems for puppet development work
  devtools::run_ruby { 'devtools-puppet-install-gems':
    command => 'gem install hiera-eyaml',
    require => [Anchor['devtools-languages-ruby-ready']],
  }

}
