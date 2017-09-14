#!/usr/bin/env bash

# This script creates a zip of our template to publish in the marketplace

rm archive.zip
mkdir tmp
cd tmp

cp ../mainTemplate.json ./mainTemplate.json

cp ../../simple/networkSecurityGroups.json ./
cp ../../simple/server.json ./
cp ../../simple/syncGateway.json ./

cp ../../extensions/* ./

zip ../archive.zip *
cd -
rm -rf tmp
