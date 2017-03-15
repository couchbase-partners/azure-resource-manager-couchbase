#!/usr/bin/env bash

echo "Running node.sh"

adminUsername=$1
adminPassword=$2
nodeDNS=$3

echo "Configuring nodes with the settings:"
echo adminUsername \'$adminUsername\'
echo adminPassword \'$adminPassword\'
echo nodeDNS \'$nodeDNS\'

# Using these instructions
# https://developer.couchbase.com/documentation/server/4.6/install/install-linux.html
