#!/usr/bin/env bash

echo "Running node.sh"

adminUsername=$1
adminPassword=$2
nodeIndex=$3
nodeCount=$4

echo "Using the settings:"
echo adminUsername \'$adminUsername\'
echo adminPassword \'$adminPassword\'
echo nodeIndex \'$nodeIndex\'
echo nodeCount \'$nodeCount\'

./install.sh
./configure.sh adminUsername adminPassword nodeIndex nodeCount
