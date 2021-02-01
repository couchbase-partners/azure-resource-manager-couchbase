#!/usr/bin/env bash

echo "Running server.sh"

version=$1
adminUsername=$2
adminPassword=$3
uniqueString=$4
location=$5
services=${6-'data,index,query,fts,eventing,analytics'}

echo "Using the settings:"
echo version \'$version\'
echo adminUsername \'$adminUsername\'
echo adminPassword \'$adminPassword\'
echo uniqueString \'$uniqueString\'
echo location \'$location\'

FILE="/var/lib/dpkg/lock-frontend"
DB="/var/lib/dpkg/lock"
if [[ -f "$FILE" ]]; then
  PID=$(lsof -t $FILE)
  echo "lock-frontend locked by $PID"
  echo "Killing $PID"
  kill -9 "${PID##p}"
  echo "$PID Killed"
  rm $FILE
  PID=$(lsof -t $DB)
  echo "DB locked by $PID"
  kill -9 "${PID##p}"
  if ps -p "${PID##p}" > /dev/null
  then
    __log_error "${PID} was not successfully killed, Installation cannot continue"
    exit 1
  fi
  rm $DB
  dpkg --configure -a
fi


echo "Installing prerequisites..."
apt-get update
apt-get -y install python-httplib2
apt-get -y install jq

echo "Installing Couchbase Server..."
wget http://packages.couchbase.com/releases/${version}/couchbase-server-enterprise_${version}-ubuntu18.04_amd64.deb
dpkg -i couchbase-server-enterprise_${version}-ubuntu18.04_amd64.deb
apt-get update
apt-get -y install couchbase-server

echo "Calling util.sh..."
source util.sh
formatDataDisk
turnOffTHPsystemd
setSwappinessToZero
adjustTCPKeepalive

echo "Configuring Couchbase Server..."

# We can get the index directly with this, but unsure how to test for success.  Come back to later...
#nodeIndex = `curl -H Metadata:true "http://169.254.169.254/metadata/instance/compute/name?api-version=2017-04-02&format=text"`
# good example here https://github.com/bonggeek/Samples/blob/master/imds/imds.sh

nodeIndex="null"
while [[ $nodeIndex == "null" ]]
do
  nodeIndex=$(curl -H Metadata:true "http://169.254.169.254/metadata/instance/compute?api-version=2017-04-02" \
    | jq ".name" \
    | sed 's/.*_//' \
    | sed 's/"//')
done

nodeDNS='vm'$nodeIndex'.server-'$uniqueString'.'$location'.cloudapp.azure.com'
rallyDNS='vm0.server-'$uniqueString'.'$location'.cloudapp.azure.com'
echo "Node DNS:  ${nodeDNS}"
echo "Rally DNS: ${rallyDNS}"
echo "Adding an entry to /etc/hosts to simulate split brain DNS..."
echo "
# Simulate split brain DNS for Couchbase
127.0.0.1 ${nodeDNS}
" >> /etc/hosts

#######################################################
####### Wait until web interface is available #########
####### Needed for the cli to work	          #########
#######################################################

checksCount=0

printf "Waiting for server startup..."
until curl -o /dev/null -s -f http://localhost:8091/ui/index.html || [[ $checksCount -ge 50 ]]; do
   (( checksCount += 1 ))
   printf "." && sleep 3
done
echo "server is up."

if [[ "$checksCount" -ge 50 ]]
then
  printf >&2 "ERROR: Couchbase Webserver is not available after script Couchbase REST readiness retry limit" 
fi

cd /opt/couchbase/bin/

echo "Running couchbase-cli node-init"
./couchbase-cli node-init \
  --cluster=$nodeDNS \
  --node-init-hostname=$nodeDNS \
  --node-init-data-path=/datadisk/data \
  --node-init-index-path=/datadisk/index \
  --node-init-analytics-path=/datadisk/analytics \
  --user=$adminUsername \
  --pass=$adminPassword

if [[ $nodeIndex == "0" ]]
then
  totalRAM=$(grep MemTotal /proc/meminfo | awk '{print $2}')
  dataRAM=$((38 * $totalRAM / 100000))
  indexRAM=$((8 * $totalRAM / 100000))

  echo "Running couchbase-cli cluster-init"
  ./couchbase-cli cluster-init \
    --cluster=$nodeDNS \
    --cluster-ramsize=$dataRAM \
    --cluster-index-ramsize=$indexRAM \
    --cluster-analytics-ramsize=$indexRAM \
    --cluster-fts-ramsize=$indexRAM \
    --cluster-eventing-ramsize=$indexRAM \
    --cluster-username=$adminUsername \
    --cluster-password=$adminPassword \
    --services=$services
else
  echo "Running couchbase-cli server-add"
  output=""
  while [[ $output != "Server $nodeDNS:8091 added" && ! $output == *"Node is already part of cluster."* ]]
  do
    output=$(./couchbase-cli server-add \
      --cluster=$rallyDNS \
      --username=$adminUsername \
      --password=$adminPassword \
      --server-add=$nodeDNS \
      --server-add-username=$adminUsername \
      --server-add-password=$adminPassword \
      --services=$services)
    echo server-add output \'$output\'
    sleep 10
  done

  echo "Running couchbase-cli rebalance"
  output=""
  while [[ ! $output =~ "SUCCESS" ]]
  do
    output=$(./couchbase-cli rebalance \
      --cluster=$rallyDNS \
      --username=$adminUsername \
      --password=$adminPassword)
    echo rebalance output \'$output\'
    sleep 10
  done

fi
