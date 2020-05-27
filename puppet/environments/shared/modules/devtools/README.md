devtools
========

Change history
--------------

* v0.1.1
    * Used standardised_remote_script_name for all selftest.rb references
* v0.1.0
    * Added support for multiple test sources when concatenating selftest.rb
* v0.0.13
    * Broke docker out into its own module
* v0.0.12
    * Added directories parameter to create directories for storing docker volumes in
* v0.0.11
    * Added daemon_parameters to allow for non-standard Docker subnet
* v0.0.10
    * Fixed missing scl requirement
* v0.0.9
    * Added docker::refresh_iptables to cope tell docker that iptables has changed since last start, e.g. CSF installed
* v0.0.8
    * Added manage_pip_conf and manage_gem_conf for templating config for eggs/gems
* v0.0.7
    * Extend selftest to work with vagrant, especially for puppet-owned certs
* v0.0.6
    * Added eyaml gem install under puppet.pp
* v0.0.5
    * Committed fix for stage_last.pp, removed grep to correctly assess test result and get text output on failure
* v0.0.4
    * Added facility to include environment variables, such as HTTP_PROXY
* v0.0.3
    * Split out Ruby into subclass
* v0.0.2
    * Added Oracle Linux to list for matching
* v0.0.1
    * Initial release, devtools principally for testing
