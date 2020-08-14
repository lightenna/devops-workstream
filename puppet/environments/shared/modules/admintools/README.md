admintools
==========

Change history
--------------

* v0.3.3
    * Added more analysis tools (iotop, sysstat) for admin support
* v0.3.2
    * Standardised params across usertools and admintools
* v0.3.1
    * Fixed admintools on Windows bug (if around file_lines)
* v0.3.0
    * Streamlined admintools to work better on Windows
* v0.2.8
    * Added Windows support for set_facts
* v0.2.7
    * Parameterised /etc/hosts for Windows
* v0.2.6
    * Removed variables that are unlikely to be overridden
* v0.2.5
    * Moved Prometheus Server proxying into webtools::proxyport
* v0.2.4
    * Added optional password protection for Prometheus server
* v0.2.3
    * Fixed default bug for standard_hosts
* v0.2.2
    * Installed ncat as serverspec dependency (be_reachable tests)
* v0.2.1
    * Fixed bug where we're only adding localhost entries
* v0.2.0
    * Added hosts.pp to manage /etc/hosts
* v0.1.4
    * Deprecate and remove old facts files, now using standard name
* v0.1.3
    * Create facts with any or all of role/environ/cluster
* v0.1.2
    * Simpler default for facts filename
* v0.1.1
    * Added defined type to create external puppet facts
* v0.1.0
    * Minor change to cert_name default to make it align with servername if unset
* v0.0.12
    * Added bind-utils/bind9-host as CSF dependency
* v0.0.11
    * Removed 'mailx' package to avoid conflict with postfix module
* v0.0.10
    * Added augeas config to stop NetworkManager from overwriting /etc/resolv.conf on Ubuntu sleeps
* v0.0.9
    * Introduced `enable` flag to make automatic updates optional
* v0.0.8
    * Added alertmanager to prometheus server config
* v0.0.7
    * Added keys, which use usertools::write_keys if set
* v0.0.6
    * Added github_over_https (default:false) to route all traffic to Github via port 443 if true
* v0.0.5
    * Included mod_proxy as needed
* v0.0.4
    * Added optional proxy server for fetching prometheus release from github.com
* v0.0.3
    * Added optional machine_notes.txt in /root for encoding machine-specific notes
* v0.0.2
    * Added Oracle Linux to list for matching
* v0.0.1
    * Initial release, admintools principally for server maintenance
