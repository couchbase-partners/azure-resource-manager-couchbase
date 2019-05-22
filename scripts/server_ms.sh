#!/usr/bin/env bash

echo "Running server_generator.sh"
echo "Parameters provided $@"
version=$1
adminUsername=$2
export CB_REST_USERNAME=$adminUsername
adminPassword=$3
export CB_REST_PASSWORD=$adminPassword
#uniqueString=$4
#location=$5
defaultSvcs='data,index,query,fts'
services=${4-$defaultSvcs}
yamlSS=$5

if [[ -z $6 ]]
then
  echo "No Couchbase Server Group setting to Group 1 ..."
  cbServerGroup='Group 1'
else
  echo "Got Couchbase Server Group $6 ..." 
  cbServerGroup=$6
fi

#rally=$7
rallyIP=$7

echo "Using the settings:"
echo version \'$version\'
#echo uniqueString \'$uniqueString\'
#echo location \'$location\'
echo services \'$services\'
echo yamlSS \'"$yamlSS"\'
echo rallyIP \'"$rallyIP"\'

echo "Installing prerequisites..."
apt-get update
apt-get -y install python-httplib2
apt-get -y install jq

echo "Installing Couchbase Server..."
wget http://packages.couchbase.com/releases/${version}/couchbase-server-enterprise_${version}-ubuntu16.04_amd64.deb
dpkg -i couchbase-server-enterprise_${version}-ubuntu16.04_amd64.deb
apt-get update
apt-get -y install couchbase-server

echo "Calling util_ms.sh..."
source util_ms.sh
formatDataDisk2
#formatDataDisk
turnOffTHPsystemd
#turnOffTransparentHugepages
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

#nodeDNS='vm'$nodeIndex'.server-'$yamlSS$uniqueString'.'$location'.cloudapp.azure.com'
#rallyDNS='vm0.server-'$rally'.'$location'.cloudapp.azure.com'
nodePrivateIP=`ip route get 1 | awk '{print $NF;exit}'`

if [[ $yamlSS == 'rallygroup' ]]
then
 echo "This is the rally node Setting rallyIP to this machines ip"
 rallyPrivateIP=$nodePrivateIP
else

 if [[ -z $rallyIP ]]
 then
  echo "rallyIP was not provided in a non Rally situation. can not continue!"
  exit 1
 else
  echo "Setting rallyPrivateIP to $rallyIP"
  rallyPrivateIP=$rallyIP
 fi 

fi
 
echo "nodeIndex: $nodeIndex"
#echo "nodeDNS: $nodeDNS"
echo "nodePrivateIP: $nodePrivateIP"
echo "rallyPrivateIP: $rallyPrivateIP"
#echo "Adding an entry to /etc/hosts to simulate split brain DNS..."
#echo "
# Simulate split brain DNS for Couchbase
# 127.0.0.1 ${nodeDNS}
# " >> /etc/hosts

cd /opt/couchbase/bin/ || exit 1

echo "Running couchbase-cli node-init"
./couchbase-cli node-init \
  --cluster=$nodePrivateIP \
  --node-init-hostname=$nodePrivateIP \
  --node-init-data-path=/datadisk/data \
  --node-init-index-path=/datadisk/index \

if [[ $nodePrivateIP == $rallyPrivateIP ]]
then
  totalRAM=$(grep MemTotal /proc/meminfo | awk '{print $2}')
  dataRAM=$((50 * $totalRAM / 100000))
  indexRAM=$((15 * $totalRAM / 100000))

  echo "Running couchbase-cli cluster-init"
  ./couchbase-cli cluster-init \
    --cluster=$nodePrivateIP \
    --cluster-ramsize=$dataRAM \
    --cluster-index-ramsize=$indexRAM \
    --cluster-username="$adminUsername" \
    --cluster-password="$adminPassword" \
    --services=$services

  echo "Creating new group: $cbServerGroup"
  output=""
  while [[ ! ($output =~ "SUCCESS: Server group created") && ! ($output =~ "ERROR: name - already exists") ]]
  do
    output=`./couchbase-cli group-manage -c $rallyPrivateIP --create --group-name $cbServerGroup`
      echo group-manage --create output \'$output\'
      sleep 10
  done

  echo "Moving to newly created group" 
  ./couchbase-cli group-manage -c $rallyPrivateIP --move-servers $nodePrivateIP --from-group 'Group 1' --to-group $cbServerGroup

else

  if [[ $nodeIndex = "0" ]]
  then
    echo "Creating new group: $cbServerGroup"
    output=""
    while [[ ! ($output =~ "SUCCESS: Server group created") && ! ($output =~ "ERROR: name - already exists") ]]
    do
      output=`./couchbase-cli group-manage -c $rallyPrivateIP --create --group-name $cbServerGroup`
        echo group-manage --create output \'"$output"\'
        sleep 10
    done

  fi

  echo "Running couchbase-cli server-add"
  output=""
  while [[ ($output != "Server $nodePrivateIP:8091 added") && ! ($output =~ "Node is already part of cluster") ]]
  do

    output=`./couchbase-cli server-add \
      --cluster=$rallyPrivateIP \
      --server-add=$nodePrivateIP \
      --server-add-username="$adminUsername" \
      --server-add-password="$adminPassword" \
      --group-name $cbServerGroup \
      --index-storage-setting default \
      --services=$services`

    echo server-add output \'"$output"\'
    sleep 10
  done

  echo "Running couchbase-cli rebalance"
  output=""
  while [[ ! $output =~ "SUCCESS" ]]
  do
    output=`./couchbase-cli rebalance --cluster=$rallyPrivateIP`
    echo rebalance output \'"$output"\'
    sleep 10
  done

fi
#set swap
#addSwapFile
#TODO: USE to create swap and restart waagent