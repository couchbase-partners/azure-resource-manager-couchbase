#!/usr/bin/env bash

./install.sh

echo "Running configure.sh"

adminUsername=$1
adminPassword=$2
nodeCount=$3

echo "Using the settings:"
echo adminUsername \'$adminUsername\'
echo adminPassword \'$adminPassword\'
echo nodeCount \'$nodeCount\'

# Using these instructions
# https://developer.couchbase.com/documentation/server/4.6/install/init-setup.html
cd /opt/couchbase/bin/

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
  echo "Adding node vm$i to the cluster."
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
