#!/usr/bin/env bash

echo "Running node.sh"

adminUsername=$1
adminPassword=$2
nodeDNS=$3

echo "Configuring nodes with the settings:"
echo adminUsername \'$adminUsername\'
echo adminPassword \'$adminPassword\'
echo nodeDNS \'$nodeDNS\'

# There are some post config steps including paging, NIC settings, etc that we should add
# https://developer.couchbase.com/documentation/server/4.6/install/install-linux.html

##### Install Couchbase

# we're currently caching the binary in GitHub.  This is not a good solution.
wget https://github.com/couchbase-partners/azure-resource-manager-couchbase/raw/master/extensions/couchbase-server-enterprise_4.6.1-debian8_amd64.deb

# Using these instructions
# https://developer.couchbase.com/documentation/server/4.6/install/ubuntu-debian-install.html
dpkg -i couchbase-server-enterprise_4.6.1-debian8_amd64.deb
apt-get update
apt-get -y install couchbase-server

##### Configure Couchbase

# Using these instructions
# https://developer.couchbase.com/documentation/server/4.6/install/init-setup.html

# curl -v -X POST -u Administrator:asdasd http://127.0.0.1:8091/node/controller/rename -d hostname=shz.localdomain

# if we're the first node then we're going to create a new cluster, otherwise
# we'll just join the existing one.
# The $nodeDNS for the first node starts with vm0-
