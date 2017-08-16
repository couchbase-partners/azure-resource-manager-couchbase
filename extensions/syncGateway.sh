#!/usr/bin/env bash

echo "Running syncGateway.sh"

uniqueString=$1
location=$2

echo "Using the settings:"
echo uniqueString \'$uniqueString\'
echo location \'$location\'

./adjust_tcp_keepalive.sh
./installSyncGateway.sh
./configureSyncGateway.sh $uniqueString $location
