#!/usr/bin/env bash

echo "Running node.sh"

adminUsername=$1
adminPassword=$2
nodeIndex=$3
uniqueString=$4
location=$5

echo "Using the settings:"
echo adminUsername \'$adminUsername\'
echo adminPassword \'$adminPassword\'
echo nodeIndex \'$nodeIndex\'
echo uniqueString \'$uniqueString\'
echo location \'$location\'

./adjust_tcp_keepalive.sh
./install.sh
./format.sh
./configure.sh $adminUsername $adminPassword $nodeIndex $uniqueString $location
