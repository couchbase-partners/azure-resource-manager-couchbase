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

  ./couchbase-cli cluster-init \
  --cluster=$vm0PrivateDNS \
  --cluster-ramsize=$dataRAM \
  --cluster-index-ramsize=$indexRAM \
  --cluster-username=$adminUsername \
  --cluster-password=$adminPassword
else
  echo "Adding node vm$nodeIndex to the cluster."
  nodePrivateDNS=`host vm$nodeIndex | awk '{print $1}'`

  output="Error"
  while [[ $output == "Error" ]]
  do
    echo "Running server-add"
    output=`./couchbase-cli server-add \
    --cluster=$vm0PrivateDNS \
    --user=$adminUsername \
    --pass=$adminPassword \
    --server-add=$nodePrivateDNS \
    --server-add-username=$adminUsername \
    --server-add-password=$adminPassword`
    output=`echo $output | cut -c 5-`
  done

  output="Error"
  while [[ $output == "Error" ]]
  do
    echo "Running rebalance"
    output=`./couchbase-cli rebalance \
    --cluster=$vm0PrivateDNS \
    --user=$adminUsername \
    --pass=$adminPassword`
    output=`echo $output | cut -c 5-`
  done

fi
