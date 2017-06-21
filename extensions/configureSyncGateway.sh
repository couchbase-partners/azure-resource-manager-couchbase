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

echo '
{
  "log": ["*"],
  "databases": {
    "db": {
      "server": "http://${serverDNS}:8091",
      "bucket": "default",
      "users": { "GUEST": { "disabled": false, "admin_channels": ["*"] } }
    }
  }
}
' > /home/sync_gateway/sync_gateway.json
