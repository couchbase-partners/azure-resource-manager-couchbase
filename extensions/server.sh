#!/usr/bin/env bash

echo "Running server.sh"
echo "Parameters provided $@"
version=$1
adminUsername=$2
adminPassword=$3
uniqueString=$4
location=$5
defaultSvcs='data,index,query,fts'
services=${6-$defaultSvcs}

if [-z $7]
then
  group=""
else
  rawGroup=$7
  group="--group-name $7 \\"
  groupEnd="--group-name $7"
fi

echo "Rally provided from commandline $8" 
if [-z $8]
then
  echo "No Rally name provided. A Rally name is required"
  #exit 1
else
  echo "Got Rally $8 ..." 
  rally=$8
fi

echo "Using the settings:"
echo version \'$version\'
echo adminUsername \'$adminUsername\'
echo adminPassword \'$adminPassword\'
echo uniqueString \'$uniqueString\'
echo location \'$location\'
echo services \'$services\'
echo group \'$group\'
echo groupEnd \'$groupEnd\'
echo rally \'$rally\'

echo "Installing prerequisites..."
apt-get update
apt-get -y install python-httplib2
apt-get -y install jq

echo "Installing Couchbase Server..."
wget http://packages.couchbase.com/releases/${version}/couchbase-server-enterprise_${version}-ubuntu14.04_amd64.deb
dpkg -i couchbase-server-enterprise_${version}-ubuntu14.04_amd64.deb
apt-get update
apt-get -y install couchbase-server

echo "Calling util.sh..."
source util.sh
formatDataDisk
turnOffTransparentHugepages
setSwappinessToZero
adjustTCPKeepalive

echo "Configuring Couchbase Server..."

# We can get the index directly with this, but unsure how to test for sucess.  Come back to later...
#nodeIndex = `curl -H Metadata:true "http://169.254.169.254/metadata/instance/compute/name?api-version=2017-04-02&format=text"`
# good example here https://github.com/bonggeek/Samples/blob/master/imds/imds.sh

nodeIndex="null"
while [[ $nodeIndex == "null" ]]
do
  nodeIndex=`curl -H Metadata:true "http://169.254.169.254/metadata/instance/compute?api-version=2017-04-02" \
    | jq ".name" \
    | sed 's/.*_//' \
    | sed 's/"//'`
done

nodeDNS='vm'$nodeIndex'.server-'$rawGroup$uniqueString'.'$location'.cloudapp.azure.com'
rallyDNS='vm0.server-'$rally$uniqueString'.'$location'.cloudapp.azure.com'

echo "Adding an entry to /etc/hosts to simulate split brain DNS..."
echo "
# Simulate split brain DNS for Couchbase
127.0.0.1 ${nodeDNS}
" >> /etc/hosts

cd /opt/couchbase/bin/

echo "Running couchbase-cli node-init"
./couchbase-cli node-init \
  --cluster=$nodeDNS \
  --node-init-hostname=$nodeDNS \
  --node-init-data-path=/datadisk/data \
  --node-init-index-path=/datadisk/index \
  --user=$adminUsername \
  --pass=$adminPassword

#if [[ $nodeIndex == "0" ]]
if [[$nodeIndex == "0" && $nodeDNS == $rallyDNS]]
then
  totalRAM=$(grep MemTotal /proc/meminfo | awk '{print $2}')
  dataRAM=$((50 * $totalRAM / 100000))
  indexRAM=$((15 * $totalRAM / 100000))

  echo "Running couchbase-cli cluster-init"
  ./couchbase-cli cluster-init \
    --cluster=$nodeDNS \
    --cluster-ramsize=$dataRAM \
    --cluster-index-ramsize=$indexRAM \
    --cluster-username=$adminUsername \
    --cluster-password=$adminPassword \
    --services=$services

  if [[-n $group]]
  then
    echo "Creating new group"
    ./couchbase-cli group-manage \
    --create \
    $groupEnd
  fi
else
  echo "Running couchbase-cli server-add"
  output=""
  while [[ $output != "Server $nodeDNS:8091 added" && ! $output =~ "Node is already part of cluster." ]]
  do
    output=`./couchbase-cli server-add \
      --cluster=$rallyDNS \
      --user=$adminUsername \
      --pass=$adminPassword \
      --server-add=$nodeDNS \
      --server-add-username=$adminUsername \
      --server-add-password=$adminPassword \
      ${group}
      --services=$services`

    echo server-add output \'$output\'
    sleep 10
  done

  echo "Running couchbase-cli rebalance"
  output=""
  while [[ ! $output =~ "SUCCESS" ]]
  do
    output=`./couchbase-cli rebalance \
      --cluster=$rallyDNS \
      --user=$adminUsername \
      --pass=$adminPassword`
    echo rebalance output \'$output\'
    sleep 10
  done

fi
