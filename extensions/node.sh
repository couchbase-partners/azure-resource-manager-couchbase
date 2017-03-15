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

# Using these instructions
# https://developer.couchbase.com/documentation/server/4.6/install/ubuntu-debian-install.html

#curl -O http://packages.couchbase.com/releases/couchbase-release/couchbase-server-enterprise_4.6-1-debian8_amd64.deb
