#!/usr/bin/env bash

echo "Running node.sh"

adminUsername=$1
adminPassword=$2
nodeIndex=$3

echo "Using the settings:"
echo adminUsername \'$adminUsername\'
echo adminPassword \'$adminPassword\'
echo nodeIndex \'$nodeIndex\'

#############################
##### Install Couchbase #####
#############################

# we're currently storing the binary in GitHub.  This is not a good solution.
wget https://github.com/couchbase-partners/azure-resource-manager-couchbase/raw/master/extensions/couchbase-server-enterprise_4.6.1-debian8_amd64.deb

# Using these instructions
# https://developer.couchbase.com/documentation/server/4.6/install/ubuntu-debian-install.html
dpkg -i couchbase-server-enterprise_4.6.1-debian8_amd64.deb
apt-get update
apt-get -y install couchbase-server

# There are some post config steps including paging, NIC settings, etc that we should add
# https://developer.couchbase.com/documentation/server/4.6/install/install-linux.html

###############################
##### Configure Couchbase #####
###############################

# Using these instructions
# https://developer.couchbase.com/documentation/server/4.6/install/init-setup.html
cd /opt/couchbase/bin/

# if we're the first node then we're going to create a new cluster, otherwise
# we'll just join the existing one.
if [[ $nodeIndex != "0" ]]
then
  exit
fi

totalRAM=$(grep MemTotal /proc/meminfo | awk '{print $2}')
dataRAM=$((60 * $totalRAM / 100000))
indexRAM=$((20 * $totalRAM / 100000))

./couchbase-cli cluster-init \
--cluster-ramsize=$dataRAM \
--cluster-index-ramsize=$indexRAM \
--cluster-username=$adminUsername \
--cluster-password=$adminPassword

# now add the node to the cluster

nodePrivateDNS=`host vm1 | awk '{print $1}'`

./couchbase-cli server-add \
--cluster=vm0 \
--user=$adminUsername \
--pass=$adminPassword \
--server-add=$nodePrivateDNS \
--server-add-username=$adminUsername \
--server-add-password=$adminPassword

./couchbase-cli rebalance \
--cluster=vm0 \
--user=$adminUsername \
--pass=$adminPassword
