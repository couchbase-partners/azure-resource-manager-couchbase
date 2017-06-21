#!/usr/bin/env bash

echo "Running server.sh"

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
./format.sh
./installServer.sh
./configureServer.sh $adminUsername $adminPassword $uniqueString $location
