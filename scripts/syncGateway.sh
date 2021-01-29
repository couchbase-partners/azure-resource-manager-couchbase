#!/usr/bin/env bash

echo "Running syncGateway.sh"

version=$1

echo "Sleeping to prevent dpkg lock"
sleep 60s #workaround for dpkg lock issue

echo "Using the settings:"
echo version \'$version\'

echo "Setting up sync gateway user"
useradd sync_gateway
echo "Creating sync_gateway home directory"
mkdir -p /home/sync_gateway/
chown sync_gateway:sync_gateway /home/sync_gateway

echo "Installing Couchbase Sync Gateway..."
wget https://packages.couchbase.com/releases/couchbase-sync-gateway/${version}/couchbase-sync-gateway-enterprise_${version}_x86_64.deb --quiet
echo "Download Complete.  Installing..."

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
  rm $DB
  dpkg --configure -a
fi

RESULT=$(dpkg -i couchbase-sync-gateway-enterprise_${version}_x86_64.deb 2>&1)
COUNT=0

while [[ $RESULT == *"dpkg frontend is locked by another process"*  && $COUNT -le 50 ]]
do
  printf "%s: %s\n" "$COUNT" "$RESULT"
  RESULT=$(dpkg -i couchbase-sync-gateway-enterprise_${version}_x86_64.deb 2>&1)
  COUNT=$((COUNT + 1))
  sleep 3s
done
echo "Installation of Sync Gateway Complete"
echo "Calling util.sh..."
source util.sh
adjustTCPKeepalive

echo "Configuring Couchbase Sync Gateway..."\

file="/home/sync_gateway/sync_gateway.json"
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
