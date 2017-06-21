#!/usr/bin/env bash

echo "Running syncGateway.sh"

adminUsername=$1
adminPassword=$2
uniqueString=$3
location=$4

echo "Using the settings:"
echo adminUsername \'$adminUsername\'
echo adminPassword \'$adminPassword\'
echo uniqueString \'$uniqueString\'
echo location \'$location\'

./adjust_tcp_keepalive.sh
./installSyncGateway.sh
./configureSyncGateway.sh $adminUsername $adminPassword $uniqueString $location
