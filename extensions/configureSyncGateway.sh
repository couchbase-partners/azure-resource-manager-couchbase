#!/usr/bin/env bash

echo "Running configureSyncGateway.sh"

adminUsername=$1
adminPassword=$2
uniqueString=$3
location=$4

echo "Using the settings:"
echo adminUsername \'$adminUsername\'
echo adminPassword \'$adminPassword\'
echo uniqueString \'$uniqueString\'
echo location \'$location\'

serverDNS='vm0.server-'$uniqueString'.'$location'.cloudapp.azure.com'

file="/home/sync_gateway/sync_gateway.json"
echo '
{
  "interface": "0.0.0.0:4984",
  "adminInterface": "0.0.0.0:4985",
  "log": ["*"],
  "databases": {
    "db": {
      "server": "http://'${serverDNS}':8091",
      "bucket": "sync_gateway",
      "users": { "GUEST": { "disabled": false, "admin_channels": ["*"] } }
    }
  }
}
' > ${file}
chmod 755 ${file}
chown couchbase ${file}
chgrp couchbase ${file}

# Need to restart to load the changes
service sync_gateway stop
service sync_gateway start
