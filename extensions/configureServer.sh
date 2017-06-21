#!/usr/bin/env bash

echo "Running configureServer.sh"

adminUsername=$1
adminPassword=$2
uniqueString=$3
location=$4

echo "Using the settings:"
echo adminUsername \'$adminUsername\'
echo adminPassword \'$adminPassword\'
echo uniqueString \'$uniqueString\'
echo location \'$location\'

apt-get -y install jq
nodeIndex=`curl -H Metadata:true "http://169.254.169.254/metadata/instance/compute?api-version=2017-03-01" \
  | jq ".name" \
  | sed 's/.*_//' \
  | sed 's/"//'`

rallyPublicDNS='vm0.'$uniqueString'.'$location'.cloudapp.azure.com'
nodePublicDNS='vm'$nodeIndex'.'$uniqueString'.'$location'.cloudapp.azure.com'

echo "Adding an entry to /etc/hosts to simulate split brain DNS"
echo "" >> /etc/hosts
echo "Simulate split brain DNS for Couchbase" >> /etc/hosts
echo "127.0.0.1 $nodePublicDNS" >> /etc/hosts
echo "" >> /etc/hosts

cd /opt/couchbase/bin/

echo "Running couchbase-cli node-init"
./couchbase-cli node-init \
  --cluster=$nodePublicDNS \
  --node-init-hostname=$nodePublicDNS \
  --node-init-data-path=/mnt/datadisk/data \
  --node-init-index-path=/mnt/datadisk/index \
  --user=$adminUsername \
  --pass=$adminPassword

if [[ $nodeIndex == "0" ]]
then
  totalRAM=$(grep MemTotal /proc/meminfo | awk '{print $2}')
  dataRAM=$((50 * $totalRAM / 100000))
  indexRAM=$((15 * $totalRAM / 100000))

  echo "Running couchbase-cli cluster-init"
  ./couchbase-cli cluster-init \
    --cluster=$nodePublicDNS \
    --cluster-ramsize=$dataRAM \
    --cluster-index-ramsize=$indexRAM \
    --cluster-username=$adminUsername \
    --cluster-password=$adminPassword \
    --services=data,index,query,fts
else
  echo "Running couchbase-cli server-add"
  output=""
  while [[ $output != "Server $nodePublicDNS:8091 added" && ! $output =~ "Node is already part of cluster." ]]
  do
    output=`./couchbase-cli server-add \
      --cluster=$rallyPublicDNS \
      --user=$adminUsername \
      --pass=$adminPassword \
      --server-add=$nodePublicDNS \
      --server-add-username=$adminUsername \
      --server-add-password=$adminPassword \
      --services=data,index,query,fts`
    echo server-add output \'$output\'
    sleep 10
  done

  echo "Running couchbase-cli rebalance"
  output=""
  while [[ ! $output =~ "SUCCESS" ]]
  do
    output=`./couchbase-cli rebalance \
      --cluster=$rallyPublicDNS \
      --user=$adminUsername \
      --pass=$adminPassword`
    echo rebalance output \'$output\'
    sleep 10
  done

fi
