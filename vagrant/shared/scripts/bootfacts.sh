#!/bin/sh

## Install custom (external) facts onto the host
##   $1 [role]
##   $2 [environ]
##   $3 [cluster]
## Write into standard directory
std_path=/etc/puppetlabs/facter/facts.d
fact_file=$std_path/puppet-facts.yaml
mkdir -p $std_path
echo "# External facts file, created by bootfacts.sh" > $fact_file
echo "---" >> $fact_file
if [ $# -ge 1 ]; then
    echo "role: \"$1\"" >> $fact_file
fi
if [ $# -ge 2 ]; then
    echo "environ: \"$2\"" >> $fact_file
fi
if [ $# -ge 3 ]; then
    echo "cluster: \"$3\"" >> $fact_file
fi
