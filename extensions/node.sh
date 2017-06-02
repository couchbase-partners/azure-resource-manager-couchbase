#!/usr/bin/env bash

echo "Running node.sh"

adminUsername=$1
adminPassword=$2
<<<<<<< HEAD
=======
nodeIndex=$3
uniqueString=$4
location=$5
>>>>>>> master

echo "Using the settings:"
echo adminUsername \'$adminUsername\'
echo adminPassword \'$adminPassword\'
<<<<<<< HEAD
=======
echo nodeIndex \'$nodeIndex\'
echo uniqueString \'$uniqueString\'
echo location \'$location\'
>>>>>>> master

./adjust_tcp_keepalive.sh
./install.sh
<<<<<<< HEAD
#./configure.sh $adminUsername $adminPassword
=======
./format.sh
./configure.sh $adminUsername $adminPassword $nodeIndex $uniqueString $location
>>>>>>> master
