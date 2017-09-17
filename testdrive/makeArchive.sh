#!/usr/bin/env bash

rm archive.zip
mkdir tmp

cp main-template.json tmp

cp ../simple/networkSecurityGroups.json tmp
cp ../simple/server.json tmp
cp ../simple/syncGateway.json tmp

cp ../extensions/* tmp

zip -r -X archive.zip tmp
rm -rf tmp
