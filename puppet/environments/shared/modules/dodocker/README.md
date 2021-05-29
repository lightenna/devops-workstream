dodocker
========

Puppet module to locally set up Docker firewall and maintenance scripts

Changelog
---------

* v0.2.3
    * Added prune script to ease maintenance
* v0.2.2
    * Added resource collector to stop Docker::System_user defined types from conflicting with usertools
* v0.2.1
    * Deepened clean for agent scrub to include shared directories
* v0.2.0
    * Added scrub_rancher_agent.sh script to selectively remove agent-related containers
* v0.1.11
    * Ensure /var/lib/kubelet directory exists before writing .dockerconfig to it
* v0.1.10
    * Modified key convert to set file ownership and mode on outputted pkcs8 key
* v0.1.9
    * Extended write_cert.pp to optionally create ca.crt
    * Extended write_cert.pp to optionally convert key (after writing) to spawn new .pkcs8
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
