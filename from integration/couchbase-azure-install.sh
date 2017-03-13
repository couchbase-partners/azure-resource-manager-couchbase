#!/bin/bash

# The MIT License (MIT)
#
# Copyright (c) 2015 Microsoft Azure
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

### 
### Warning! This script partitions and formats disk information be careful where you run it
###          This script is currently under development and has only been tested on Ubuntu images in Azure
###          This script is not currently idempotent and only works for provisioning
###

# Log method to control/redirect log output
log()
{    
    echo $1 >> provision-couchbase.log
}

log "Begin execution of couchbase script extension on ${HOSTNAME}"
 
if [ "${UID}" -ne 0 ];
then
    log "Script executed without root permissions"
    echo "You must be root to run this program." >&2
    exit 3
fi

# TEMP FIX - Re-evaluate and remove when possible
# This is an interim fix for hostname resolution in current VM
if grep -q "${HOSTNAME}" /etc/hosts
then
  echo "${HOSTNAME}found in /etc/hosts"
else
  echo "${HOSTNAME} not found in /etc/hosts"
  # Append it to the hsots file if not there
  echo "127.0.0.1 $(hostname)" >> /etc/hosts
  log "hostname ${HOSTNAME} added to /etchosts"
fi

#Script Parameters
PACKAGE_NAME=""
CLUSTER_NAME=""
IP_LIST=""
ADMINISTRATOR=""
PASSWORD=""
# Minimum VM size we are assuming is A2, which has 3.5GB, 2800MB is about 80% as recommended
TOTAL_RAM=$(grep MemTotal /proc/meminfo | awk '{print $2}')
RAM_FOR_COUCHBASE=$((60 * $TOTAL_RAM))
DATA_RAM_FOR_COUCHBASE=$(($RAM_FOR_COUCHBASE / 100000))
RAM_FOR_COUCHBASE=$((20 * $TOTAL_RAM))
INDEX_RAM_FOR_COUCHBASE=$(($RAM_FOR_COUCHBASE / 100000))
IS_LAST_NODE=0

#Process the received arguments
while getopts d:n:i:a:p:l optname; do
    log "Option $optname set with value ${OPTARG}"
  case $optname in
    d) #Couchbase package name
      PACKAGE_NAME=${OPTARG}
      ;;
    n)  #set cluster name
      CLUSTER_NAME=${OPTARG}
      ;;
    i) #Static IPs of the cluster members
      IP_LIST=${OPTARG}
      ;;    
    a) #Adminsitrator name
      ADMINISTRATOR=${OPTARG}
      ;; 
p) #Password for the admin
  PASSWORD=${OPTARG}
  ;;         
l) #is this for the last node?
  IS_LAST_NODE=1
  ;;          
  esac
done
# install_cb is removed as we install from template and  CB image azure market place 
DATA_DISKS="/datadisks"
DATA_MOUNTPOINT="$DATA_DISKS/disk1"
COUCHBASE_DATA="$DATA_MOUNTPOINT/couchbase"


# Stripe all of the data disks
bash ./vm-disk-utils-0.1.sh -b $DATA_DISKS -s


mkdir -p "$COUCHBASE_DATA"
chown -R couchbase:couchbase "$COUCHBASE_DATA"
chmod 755 "$COUCHBASE_DATA"

IFS='-' read -a HOST_IPS <<< "$IP_LIST"

#Get the IP Addresses on this machine
declare -a MY_IPS=`ifconfig | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0.1'`
MY_IP=""
declare -a MEMBER_IP_ADDRESSES=()
#for (( n=0 ; n<("${HOST_IPS[1]}"+0) ; n++))
#Skip last node since this part of script will be executed from it
for (( n=0 ; n<("${HOST_IPS[1]}"+0) -1 ; n++))
do
  HOST="${HOST_IPS[0]}${n}"
  if ! [[ "${MY_IPS[@]}" =~ "${HOST}" ]]; then
      hostlookup=$(nslookup "$HOST" | grep Name: | awk '{print $2}')
      MEMBER_IP_ADDRESSES+=($hostlookup)
  fi
done


myhostname=$(hostname -f)
MY_IP=$(nslookup "$myhostname" | grep Name: | awk '{print $2}')
echo "last node IP", $MY_IP

KNOWN_NODES=
log "Is last node? ${IS_LAST_NODE}"

echo "USER_NAME", $ADMINISTRATOR >> /tmp/instances.txt
echo "PASSWORD", $PASSWORD >> /tmp/instances.txt
echo "DATA_PATH", $COUCHBASE_DATA >> /tmp/instances.txt
echo "INDEX_QUOTA", $INDEX_RAM_FOR_COUCHBASE >> /tmp/instances.txt
echo "DATA_QUOTA", $DATA_RAM_FOR_COUCHBASE >> /tmp/instances.txt

if [ "$IS_LAST_NODE" -eq 1 ]; then
  echo "master", $MY_IP >>  /tmp/instances.txt
  for (( i = 0; i < ${#MEMBER_IP_ADDRESSES[@]}; i++ )); do
  echo "slave", ${MEMBER_IP_ADDRESSES[$i]} >> /tmp/instances.txt
 done 
fi

chmod +x /tmp/instances.txt
python azure_cluster.py
rm -f  /tmp/instances.txt