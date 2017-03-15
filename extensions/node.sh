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

if [[ $nodeIndex == "0" ]]
then
  ./configure.sh adminUsername adminPassword nodeCount
fi
