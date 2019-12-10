[devopera](http://devopera.com)-[domotd](http://devopera.com/module/domotd)
=============

The Message of the Day (MOTD) can be used to show system information at login time.  For the Devopera family of modules, it shows a summary of host information (size/spec of machine), network setup (IP/MAC), what's installed (profiles and services) and exposed ports.

Changelog
---------

2019-12-10 (v0.11.0)

  * added service_provider to show in MOTD

2019-12-09 (v0.10.0)

  * added tcp_in_list string to allow showing a port list directly from the firewall
  * added tcp_in_hash hash to allow showing a port list when stored as the first key in a hash

2013-09-28 (v0.9.0)

  * rewritten for both CentOS and Ubuntu

2013-09-03

  * /etc/issue now dynamically generated from /etc/issue.template like motd.template

2013-05-08

  * Added /etc/issue message to show IP/MAC address before login

How it works
------------

In CentOS, the message of the day lives in /etc/motd.  It is optionally updated from a template in /etc/motd.template by a script appended to /etc/rc.local.
In Ubuntu, the message of the day is typically composed from fragments in /etc/update-motd.d/*.  We therefore compose the motd in a temporary folder (/etc/puppetlabs/puppet/tmp), optionally from a template in the same directory.  update-motd.d/15-devopera-motd then displays content from that temporary folder.

Usage
-----

Setup a simple informative message of the day at puppet-time

    class { 'domotd' : }

Refresh frequently changing information at machine start-up (dynamics)

    class { 'domotd' :
      use_dynamics => true,
    }


Copyright and License
---------------------

Copyright (C) 2012 Lightenna Ltd

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
