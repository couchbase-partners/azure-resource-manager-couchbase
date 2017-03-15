#!/usr/bin/env bash

echo "Running install.sh"

# we're currently storing the binary in GitHub.  This is not a good solution.
wget https://github.com/couchbase-partners/azure-resource-manager-couchbase/raw/master/extensions/couchbase-server-enterprise_4.6.1-debian8_amd64.deb

# Using these instructions
# https://developer.couchbase.com/documentation/server/4.6/install/ubuntu-debian-install.html
dpkg -i couchbase-server-enterprise_4.6.1-debian8_amd64.deb
apt-get update
apt-get -y install couchbase-server

# There are some post config steps including paging, NIC settings, etc that we should add
# https://developer.couchbase.com/documentation/server/4.6/install/install-linux.html

#Warning: Transparent hugepages looks to be active and should not be.
#Please look at http://bit.ly/1ZAcLjD as for how to PERMANENTLY alter this setting.

#Warning: Swappiness is not set to 0.
#Please look at http://bit.ly/1k2CtNn as for how to PERMANENTLY alter this setting.
