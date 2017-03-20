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
  totalRAM=$(grep MemTotal /proc/meminfo | awk '{print $2}')
  dataRAM=$((60 * $totalRAM / 100000))
  indexRAM=$((20 * $totalRAM / 100000))

  echo "Running couchbase-cli cluster-init"
  ./couchbase-cli cluster-init \
  --cluster=$vm0PrivateDNS \
  --cluster-ramsize=$dataRAM \
  --cluster-index-ramsize=$indexRAM \
  --cluster-username=$adminUsername \
  --cluster-password=$adminPassword
else
  nodePrivateDNS=`host vm$nodeIndex | awk '{print $1}'`

  echo "Running couchbase-cli server-add"
  output=""
  while [[ $output != "Server $nodePrivateDNS:8091 added" && ! $output =~ "Node is already part of cluster."]]
  do
    output=`./couchbase-cli server-add \
    --cluster=$vm0PrivateDNS \
    --user=$adminUsername \
    --pass=$adminPassword \
    --server-add=$nodePrivateDNS \
    --server-add-username=$adminUsername \
    --server-add-password=$adminPassword`
    echo server-add output \'$output\'
  done

  echo "Running couchbase-cli rebalance"
  output=""
  while [[ ! $output =~ "SUCCESS" ]]
  do
    output=`./couchbase-cli rebalance \
    --cluster=$vm0PrivateDNS \
    --user=$adminUsername \
    --pass=$adminPassword`
    echo rebalance output \'$output\'
  done

fi
