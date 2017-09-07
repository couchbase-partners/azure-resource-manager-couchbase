#!/usr/bin/env bash

# This script creates zips of our template to publish in the marketplace

function makeArchive()
{
  license=$1

  mkdir tmp
  cd tmp

  cp ../mainTemplate-${license}.json ./mainTemplate.json
  cp ../createUiDefinition.json ./

  cp ../../simple/networkSecurityGroups.json ./
  cp ../../simple/server.json ./
  cp ../../simple/syncGateway.json ./

  cp ../../extensions/* ./

  zip ../archive-${license}.zip *
  cd -
  rm -rf tmp
}

makeArchive byol
makeArchive hourly_pricing
