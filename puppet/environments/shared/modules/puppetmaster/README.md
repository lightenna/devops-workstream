puppetmaster
============

Notes
-----
* `puppet` user needs to be able to read the puppet manifests that are checked out by control_repo.

Change history
--------------

* v0.4.0
    * Moved back to using shared webtools::write_cert
* v0.3.6
    * Parameterised puppetfile install
* v0.3.5
    * Clean up comments
* v0.3.4
    * Removed activate_this.py reference as now deprecated
* v0.3.3
    * Removed virtualenv_version as field removed from puppetboard
* v0.3.2
    * Refactored update_cadence into safe_repo to allow other repos to be automatically updated
* v0.3.1
    * Updated write_cert to cope with pkcs8 key conversion
* v0.3.0
    * Forced puppetboard vhost to include SSLVerifyClient ('none') and SSLCACertificateFile (bundle)
* v0.2.5
    * Wrapped ensure_resources because getting duplicate resource errors
* v0.2.4
    * Standardised variable naming on write_cert
* v0.2.3
    * Corrected non-defined puppetboard cert_name to FQDN to match the default httpd config
* v0.2.2
    * Renamed .htpasswd file to avoid potential collisions
    * Standardised naming of the htpasswd attributes
* v0.2.1
    * Updated Puppetboard to v2.1.2.
    * Released lock on PuppetDB after patches to Puppetboard.
* v0.0.20
    * Locked PuppetDB at 6.9.0 to avoid pypuppetdb problem with 6.9.1
* v0.0.19
    * Moved to Apache 2.4 configuration <RequireAny> for Puppetboard vhost
* v0.0.18
    * Added dependency on postgresql if PuppetDB database is postgres
* v0.0.17
    * Only include git if managing repo
* v0.0.16
    * Parameterised puppetboard version for future updates; fixed template paths
* v0.0.15
    * Updated puppetboard to version 2.0.0, which requires Python 3, which requires HTTPd 2.4.30
* v0.0.14
    * Create localhost host entry for puppet (but not FQDN)
* v0.0.13
    * Set puppetboard to use offline mode by default, to avoid call out for CDN versions of jquery etc.
* v0.0.12
    * Reverted to more reliable defaults for puppetmaster
* v0.0.11
    * Forced vcsrepo to check for (require) $basedir before trying to checkout into it
* v0.0.10
    * Changed default certificate name to match cert on machine by default
* v0.0.9
    * Added notify on ini_settings as they could potentially change the puppetserver config
* v0.0.8
    * Improved containment on the puppetmaster sub-classes
* v0.0.7
    * Moved anchor { 'puppetmaster-control_repo-r10k-ready': } to allow for non-management
* v0.0.6
    * Introduce git dependency for control_repo and puppetboard
* v0.0.5
    * Reduced dependencies to usertools only
        * Now using local write_cert.pp
