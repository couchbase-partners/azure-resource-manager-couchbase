#!/usr/bin/env bash

echo "Running configure.sh"

adminUsername=$1
adminPassword=$2
nodeIndex=$3

echo "Using the settings:"
echo adminUsername \'$adminUsername\'
echo adminPassword \'$adminPassword\'
echo nodeIndex \'$nodeIndex\'

# Using these instructions
# https://developer.couchbase.com/documentation/server/4.6/install/init-setup.html
cd /opt/couchbase/bin/

if [[ $nodeIndex == "0" ]]
then
  totalRAM=$(grep MemTotal /proc/meminfo | awk '{print $2}')
  dataRAM=$((60 * $totalRAM / 100000))
  indexRAM=$((20 * $totalRAM / 100000))

  ./couchbase-cli cluster-init \
  --cluster-ramsize=$dataRAM \
  --cluster-index-ramsize=$indexRAM \
  --cluster-username=$adminUsername \
  --cluster-password=$adminPassword
else
  echo "Adding node vm$nodeIndex to the cluster."
  nodePrivateDNS=`host vm$nodeIndex | awk '{print $1}'`

  ./couchbase-cli server-add \
  --cluster=vm0 \
  --user=$adminUsername \
  --pass=$adminPassword \
  --server-add=$nodePrivateDNS \
  --server-add-username=$adminUsername \
  --server-add-password=$adminPassword
fi

# Ideally we want to test if the cluster has added all the nodes and then call rebalance.
# For now we're just going to call it every time we run this script
./couchbase-cli rebalance \
--cluster=vm0 \
--user=$adminUsername \
--pass=$adminPassword
