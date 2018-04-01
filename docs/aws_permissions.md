Workstream
==========

AWS Permissions
-------

A comprehensive `terraform apply` run of all the modules in this repo requires a variety of AWS permissions.  At the moment I'm using:

* AWSMarketplaceFullAccess
* AmazonEC2FullAccess

This is not a recommendation for the permission list you should be using in production, only an example of the kind of laissez-faire permission list that makes experimenting with AWS easy.
AWS has a limit of 10 manually assigned permissions per user, so please:

* create a group
* assign all the permissions to the group
* assign the group to the user