puppetmaster
============

Notes
-----
* `puppet` user needs to be able to read the puppet manifests that are checked out by control_repo.

Change history
--------------

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
