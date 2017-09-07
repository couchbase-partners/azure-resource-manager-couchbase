#!/usr/bin/env bash

# This script creates zips of our template to publish in the marketplace

function makeArchive()
{
  license=$1
  
  mkdir tmp
  cd tmp

  cp ../../extensions/* ./
  cp ../../simple/* ./

  # Do this after and overwrite mainTemplate.json
  cp ../mainTemplate-${license}.json ./mainTemplate.json
  cp ../createUiDefinition.json ./

  # Drop some files that don't need to be in the archive
  rm README.md
  rm deploy.sh
  rm deploy.ps1
  rm mainTemplateParameters.json

  zip ../archive-${license}.zip *
  cd -
  rm -rf tmp
}

makeArchive byol
markArchive hourly_pricing
