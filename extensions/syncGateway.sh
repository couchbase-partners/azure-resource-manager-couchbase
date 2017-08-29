#!/usr/bin/env bash

echo "Running syncGateway.sh"

uniqueString=$1
location=$2

echo "Using the settings:"
echo uniqueString \'$uniqueString\'
echo location \'$location\'

echo "Installing Couchbase Sync Gateway..."
wget https://packages.couchbase.com/releases/couchbase-sync-gateway/1.4.1/couchbase-sync-gateway-enterprise_1.4.1-3_x86_64.deb
dpkg -i couchbase-sync-gateway-enterprise_1.4.1-3_x86_64.deb

echo "Calling util.sh..."
source util.sh
adjustTCPKeepalive

echo "Configuring Couchbase Sync Gateway..."

# Public DNS
#rallyDNS='vm0.server-'$uniqueString'.'$location'.cloudapp.azure.com'

# Private DNS
nodeDNS=`nslookup \`hostname\` | grep Name | sed 's/Name:\t//'`
rallyDNS=`echo ${nodeDNS} | sed 's/syncgateway[0-9][0-9][0-9][0-9][0-9][0-9]/server000000/'`

file="/home/sync_gateway/sync_gateway.json"
echo '
{
  "interface": "0.0.0.0:4984",
  "adminInterface": "0.0.0.0:4985",
  "log": ["*"],
  "databases": {
    "database": {
      "server": "http://'${rallyDNS}':8091",
      "bucket": "sync_gateway",
      "users": {
        "GUEST": { "disabled": false, "admin_channels": ["*"] }
      }
    }
  }
}
' > ${file}
chmod 755 ${file}
chown sync_gateway ${file}
chgrp sync_gateway ${file}

# Need to restart to load the changes
service sync_gateway stop
service sync_gateway start
