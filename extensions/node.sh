#!/usr/bin/env bash

echo "Running node.sh"

adminUsername=$1
adminPassword=$2
nodeIndex=$3
nodeCount=$4

echo "Using the settings:"
echo adminUsername \'$adminUsername\'
echo adminPassword \'$adminPassword\'
echo nodeIndex \'$nodeIndex\'
echo nodeCount \'$nodeCount\'

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

#Warning: Transparent hugepages looks to be active and should not be.
#Please look at http://bit.ly/1ZAcLjD as for how to PERMANENTLY alter this setting.

#Warning: Swappiness is not set to 0.
#Please look at http://bit.ly/1k2CtNn as for how to PERMANENTLY alter this setting.

###############################
##### Configure Couchbase #####
###############################

# Using these instructions
# https://developer.couchbase.com/documentation/server/4.6/install/init-setup.html
cd /opt/couchbase/bin/

# if we're the first node then we're going to create a new cluster and add nodes
# otherwise we just exit
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

for (( i=1; i<$nodeCount; i++ ))
do
  nodePrivateDNS=`host vm$i | awk '{print $1}'`
  ./couchbase-cli server-add \

  --cluster=vm0 \
  --user=$adminUsername \
  --pass=$adminPassword \
  --server-add=$nodePrivateDNS \
  --server-add-username=$adminUsername \
  --server-add-password=$adminPassword
done

./couchbase-cli rebalance \
--cluster=vm0 \
--user=$adminUsername \
--pass=$adminPassword
