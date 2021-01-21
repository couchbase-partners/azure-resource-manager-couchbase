#!/usr/bin/env bash

echo "Running server.sh"

version=$1
adminUsername=$2
adminPassword=$3
rallyFQDN=$4
nodeDNS=$5

echo "Using the settings:"
echo version \'"$version"\'
echo adminUsername \'"$adminUsername"\'
echo adminPassword \'"$adminPassword"\'
echo rallyFQDN \'"$rallyFQDN"\'
echo nodeDNS \'"$nodeDNS"\'


echo "Installing prerequisites..."
apt-get update
apt-get -y install python-httplib2
apt-get -y install jq

echo "Installing Couchbase Server..."
wget http://packages.couchbase.com/releases/"${version}"/couchbase-server-enterprise_"${version}"-ubuntu18.04_amd64.deb
dpkg -i couchbase-server-enterprise_"${version}"-ubuntu18.04_amd64.deb

apt-get update
apt-get -y install couchbase-server

echo "Calling util.sh..."
# shellcheck disable=SC1091
source util.sh
formatDataDisk
turnOffTransparentHugepages
setSwappinessToZero
adjustTCPKeepalive

echo "Configuring Couchbase Server..."

nodeIndex=$(hostname | tail -c -2)

#nodeDNS=`echo $rallyFQDN | sed s/server0-/server${nodeIndex}-/`
rallyDNS=${rallyFQDN}

echo "Adding an entry to /etc/hosts to simulate split brain DNS..."
echo "
# Simulate split brain DNS for Couchbase
127.0.0.1 ${nodeDNS}
" >> /etc/hosts

cd /opt/couchbase/bin/ || { echo "Failed to change to couchbase directory."; exit 1; }

echo "Running couchbase-cli node-init"
echo "./couchbase-cli node-init \
  --cluster=$nodeDNS \
  --node-init-hostname=$nodeDNS \
  --node-init-data-path=/datadisk/data \
  --node-init-index-path=/datadisk/index \
  --user=$adminUsername \
  --pass=$adminPassword"
./couchbase-cli node-init \
  --cluster="$nodeDNS" \
  --node-init-hostname="$nodeDNS" \
  --node-init-data-path=/datadisk/data \
  --node-init-index-path=/datadisk/index \
  --user="$adminUsername" \
  --pass="$adminPassword"

if [[ $nodeIndex == "0" ]]
then
# TODO: would be nice to check vm memory and set total ram accordingly. There's been times that we've been burned by this static calculation.
  totalRAM=$(grep MemTotal /proc/meminfo | awk '{print $2}')
  dataRAM=$((50 * "$totalRAM" / 100000))
  indexRAM=$((15 * "$totalRAM" / 100000))

  echo "Running couchbase-cli cluster-init"
  echo "./couchbase-cli cluster-init \
    --cluster=$nodeDNS \
    --cluster-ramsize=$dataRAM \
    --cluster-index-ramsize=$indexRAM \
    --cluster-username=$adminUsername \
    --cluster-password=$adminPassword \
    --services=data,index,query,fts"
  ./couchbase-cli cluster-init \
    --cluster="$nodeDNS" \
    --cluster-ramsize="$dataRAM" \
    --cluster-index-ramsize="$indexRAM" \
    --cluster-username="$adminUsername" \
    --cluster-password="$adminPassword" \
    --services=data,index,query,fts
else
  echo "Running couchbase-cli server-add"
  output=""
  while [[ $output != "Server $nodeDNS:8091 added" && ! $output == *"Node is already part of cluster."* ]]
  do
    output=$(./couchbase-cli server-add \
      --cluster="$rallyDNS" \
      --username="$adminUsername" \
      --password="$adminPassword" \
      --server-add="$nodeDNS" \
      --server-add-username="$adminUsername" \
      --server-add-password="$adminPassword" \
      --services=data,index,query,fts)
    echo "$output"
    echo server-add output \'"$output"\'
    sleep 10
  done

  echo "Running couchbase-cli rebalance"
  output=""
  while [[ ! $output =~ "SUCCESS" ]]
  do
    output=$(./couchbase-cli rebalance \
      --cluster="$rallyDNS" \
      --username="$adminUsername" \
      --password="$adminPassword")
    echo "$output"
    echo rebalance output \'"$output"\'
    sleep 10
  done

fi
