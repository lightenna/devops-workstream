dodocker
========

Puppet module to locally set up Docker firewall and maintenance scripts

Changelog
---------

* v0.1.8
    * Added before => [] to place certs before 'docker-ready' anchor
    * Insisted upon 'docker-ready' before starting docker service
* v0.1.7
    * Wrapped ensure_resources because getting duplicate resource errors
* v0.1.6
    * Deprecated daemon_parameters as can (and is) now done using hiera
    * Converted use of $user/group/mode to apply, by default, to directories and certs (match with service-container user)
* v0.1.5
    * Added certificate writing to allow isolated containers limited access to sensitive certs
* v0.1.4
    * Switch to jsherz CSF integration to tell docker not to automatically open ports on the external firewall
    * Switched out JSON template for to_json_pretty() stdlib function
    * Set daemon parameters from hiera either using docker:: vars or daemon_parameters hash
* v0.1.3
    * Ensure that all docker::registry resources have completed before running authspread
* v0.1.2
    * Extracted .auths from .docker/config.json to produce .dockercfg file
* v0.1.1
    * Honed process restart for scrub script
* v0.1.0
    * Added authspread to manage kubelet authentication using puppet
* v0.0.4
    * Moved longhorn deps into this module
* v0.0.3
    * Added notify on csf resources
* v0.0.2
    * Tweaked docker.sh script to handle containers that return a bad netmode (container:fff)
* v0.0.1
    * Created new module to handle environment changes and maintenance scripts for docker
