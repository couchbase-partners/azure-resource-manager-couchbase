#!/usr/bin/env bash

echo "Running syncGateway.sh"

version=$1

echo "Sleeping to prevent dpkg lock"
sleep 20s #workaround for dpkg lock issue

echo "Using the settings:"
echo version \'$version\'

echo "Installing Couchbase Sync Gateway..."
wget https://packages.couchbase.com/releases/couchbase-sync-gateway/${version}/couchbase-sync-gateway-enterprise_${version}_x86_64.deb
dpkg -i couchbase-sync-gateway-enterprise_${version}_x86_64.deb

echo "Calling util.sh..."
source util.sh
adjustTCPKeepalive

echo "Configuring Couchbase Sync Gateway..."
file="/home/sync_gateway/sync_gateway.json"
#TODO - Create bucket and connect sync gateway too it?
echo '
{
  "interface": "0.0.0.0:4984",
  "adminInterface": "0.0.0.0:4985",
  "log": ["*"]
}
' > ${file}
chmod 755 ${file}
chown sync_gateway ${file}
chgrp sync_gateway ${file}

# Need to restart to load the changes
service sync_gateway stop
service sync_gateway start
