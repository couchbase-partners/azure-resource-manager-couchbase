#!/usr/bin/env bash

function makeArchive()
{
  license=$1
  rm archive-${license}.zip
  mkdir tmp

  cp mainTemplate-${license}.json tmp/mainTemplate.json
  cp createUiDefinition.json tmp

  cp ../simple/networkSecurityGroups.json tmp
  cp ../simple/server.json tmp
  cp ../simple/syncGateway.json tmp

  cp ../extensions/* tmp

  zip -r -X archive-${license}.zip tmp
  rm -rf tmp
}

makeArchive byol
makeArchive hourly_pricing
