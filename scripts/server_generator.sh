#!/usr/bin/env bash

echo "Running server_generator.sh"
echo "Parameters provided $@"
version=$1
adminUsername=$2
export CB_REST_USERNAME=$adminUsername
adminPassword=$3
export CB_REST_PASSWORD=$adminPassword
uniqueString=$4
location=$5
defaultSvcs='data,index,query,fts'
services=${6-$defaultSvcs}
yamlSS=$7 #VMSSgroup is the generator yamls
rallyConstant=$8 #from deployment*.py

if [[ -z $9 ]]
then
  echo "No Couchbase Server Group setting to Group 1 ..."
  cbServerGroup='Group 1'
else
  echo "Got Couchbase Server Group $9 ..." 
  cbServerGroup=$9
fi

echo "Using the settings:"
echo version \'"$version"\'
echo uniqueString \'"$uniqueString"\'
echo location \'"$location"\'
echo services \'"$services"\'
echo yamlSS \'"$yamlSS"\'
echo rallyConstant \'"$rallyConstant"\'

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

nodeDNS='vm'$nodeIndex'.server-'$yamlSS'-'$uniqueString'.'$location'.cloudapp.azure.com'
rallyDNS='vm0.server-'$rallyConstant'-'$uniqueString'.'$location'.cloudapp.azure.com'
echo "nodeDNS: $nodeDNS"
echo "rallyDNS: $rallyDNS"

#nodePrivateIP=`ip route get 1 | awk '{print $NF;exit}'`

# if [[ $yamlSS == 'rallygroup' ]]
# then
#  echo "This is the rally node Setting rallyIP to this machines ip"
#  rallyPrivateIP=$nodePrivateIP
# else

#  if [[ -z $rallyIP ]]
#  then
#   echo "rallyIP was not provided in a non Rally situation. can not continue!"
#   exit 1
#  else
#   echo "Setting rallyPrivateIP to $rallyIP"
#   rallyPrivateIP=$rallyIP
#  fi 

# fi

echo "Adding an entry to /etc/hosts to simulate split brain DNS..."
echo "
# Simulate split brain DNS for Couchbase
127.0.0.1 ${nodeDNS}
" >> /etc/hosts

#cd /opt/couchbase/bin/ || exit 1
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
  --node-init-analytics-path=/datadisk/analytics

if [[ $nodeDNS == $rallyDNS ]]
then
  totalRAM=$(grep MemTotal /proc/meminfo | awk '{print $2}')
  dataRAM=$((38 * $totalRAM / 100000))
  indexRAM=$((8 * $totalRAM / 100000))

  echo "Running couchbase-cli cluster-init"
  ./couchbase-cli cluster-init \
    --cluster=$rallyDNS \
    --cluster-ramsize=$dataRAM \
    --cluster-index-ramsize=$indexRAM \
    --cluster-fts-ramsize=$indexRAM \
    --cluster-eventing-ramsize=$indexRAM \
    --cluster-username="$adminUsername" \
    --cluster-password="$adminPassword" \
    --services=$services

  echo "Creating new group: $cbServerGroup"
  output=""
  while [[ ! ($output =~ "SUCCESS: Server group created") && ! ($output =~ "ERROR: name - already exists") ]]
  do
    output=`./couchbase-cli group-manage -c $rallyDNS --create --group-name $cbServerGroup`
      echo group-manage --create output \'$output\'
      sleep 10
  done

  echo "Moving to newly created group" 
  ./couchbase-cli group-manage -c $rallyDNS --move-servers $nodeDNS --from-group 'Group 1' --to-group $cbServerGroup

else

  #if [[ $nodeDNS == $rallyDNS ]]
  #then
  echo "Creating new group: $cbServerGroup"
  output=""
  while [[ ! ($output =~ "SUCCESS: Server group created") && ! ($output =~ "ERROR: name - already exists") ]]
  do
    output=`./couchbase-cli group-manage -c $rallyDNS --create --group-name $cbServerGroup`
      echo group-manage --create output \'"$output"\'
      sleep 10
  done

  #fi

  echo "Running couchbase-cli server-add"
  output=""
  while [[ ! "$output" =~ "SUCCESS" ]]
  do

    output=`./couchbase-cli server-add \
      --cluster=$rallyDNS \
      --server-add=$nodeDNS \
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
    output=`./couchbase-cli rebalance --cluster=$rallyDNS`
    echo rebalance output \'"$output"\'
    sleep 10
  done

fi
