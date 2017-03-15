#!/usr/bin/env bash

echo "Running node.sh"

adminUsername=$1
adminPassword=$2
nodeIndex=$3
uniqueString=$4
location=$5

echo "Configuring nodes with the settings:"
echo adminUsername \'$adminUsername\'
echo adminPassword \'$adminPassword\'
echo nodeIndex \'$nodeIndex\'
echo uniqueString \'$uniqueString\'
echo location \'$location\'

# This is the rally point for our cluster
# an example DNS record is vm0-ixymcna6yezhc.westus.cloudapp.azure.com
rallyPointDNS="vm0-"$uniqueString"."$location".cloudapp.azure.com"

##### Install Couchbase

# we're currently caching the binary in GitHub.  This is not a good solution.
wget https://github.com/couchbase-partners/azure-resource-manager-couchbase/raw/master/extensions/couchbase-server-enterprise_4.6.1-debian8_amd64.deb

# Using these instructions
# https://developer.couchbase.com/documentation/server/4.6/install/ubuntu-debian-install.html
dpkg -i couchbase-server-enterprise_4.6.1-debian8_amd64.deb
apt-get update
apt-get -y install couchbase-server

# There are some post config steps including paging, NIC settings, etc that we should add
# https://developer.couchbase.com/documentation/server/4.6/install/install-linux.html

##### Configure Couchbase

# Using these instructions
# https://developer.couchbase.com/documentation/server/4.6/install/init-setup.html

# if we're the first node then we're going to create a new cluster, otherwise
# we'll just join the existing one.

# Set up services

# the doc has an example with data and query as types. I'm getting unknown for
# those, so they may be deprecated.

# seem like options are: index, fts, n1ql, kv
# I'm getting a memory allocation issue when I try to do all four.  Trying without fts for now.
curl -v http://localhost:8091/node/controller/setupServices -d 'services=kv%2Cn1ql%2Cindex'

# Initialize a node
curl -v http://localhost:8091/nodes/self/controller/settings -d 'path=%2Fopt%2Fcouchbase%2Fvar%2Flib%2Fcouchbase%2Fdata&index_path=%2Fopt%2Fcouchbase%2Fvar%2Flib%2Fcouchbase%2Fdata'

# Set up your administrator-username and password
# doesn't seem to work
# Error is: All parameters must be given
curl -v http://localhost:8091/settings/web -d password=$adminPassword -d username=$adminUsername

curl -v http://localhost:8091/controller/addNode -d hostname=$rallyPointDNS -d 'services=kv%2Cn1ql%2Cindex'

curl -v http://localhost:8091/controller/rebalance
