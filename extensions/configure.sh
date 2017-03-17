#!/usr/bin/env bash

echo "Running configure.sh"

adminUsername=$1
adminPassword=$2
nodeIndex=$3

echo "Using the settings:"
echo adminUsername \'$adminUsername\'
echo adminPassword \'$adminPassword\'
echo nodeIndex \'$nodeIndex\'

cd /opt/couchbase/bin/
vm0PrivateDNS=`host vm0 | awk '{print $1}'`

if [[ $nodeIndex == "0" ]]
then
  echo "Initializing a new cluster."
  totalRAM=$(grep MemTotal /proc/meminfo | awk '{print $2}')
  dataRAM=$((60 * $totalRAM / 100000))
  indexRAM=$((20 * $totalRAM / 100000))

  ./couchbase-cli node-init \
  --cluster=$vm0PrivateDNS \
  --user=$adminUsername \
  --password=$adminPassword

  ./couchbase-cli cluster-init \
  --cluster=$vm0PrivateDNS \
  --cluster-ramsize=$dataRAM \
  --cluster-index-ramsize=$indexRAM \
  --cluster-username=$adminUsername \
  --cluster-password=$adminPassword
else
  echo "Adding node vm$nodeIndex to the cluster."
  nodePrivateDNS=`host vm$nodeIndex | awk '{print $1}'`

  # Need to handle this error
  #Error: Failed to add server vm4.rtb52c2mq31ebnff3wi3cbqckb.dx.internal.cloudapp.net:8091: Adding nodes to not provisioned nodes is not allowed.

  ./couchbase-cli server-add \
  --cluster=$vm0PrivateDNS \
  --user=$adminUsername \
  --pass=$adminPassword \
  --server-add=$nodePrivateDNS \
  --server-add-username=$adminUsername \
  --server-add-password=$adminPassword
fi

# need to handle the rebalance error
#./couchbase-cli rebalance \
#--cluster=$vm0PrivateDNS \
#--user=$adminUsername \
#--pass=$adminPassword
