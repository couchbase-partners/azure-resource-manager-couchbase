#!/usr/bin/env bash

function makeArchive()
{
  license=$1
  rm archive-${license}.zip
  mkdir tmp

  cp mainTemplate-${license}.json tmp/mainTemplate.json
  cp createUiDefinition.json tmp
  cp ../extensions/* tmp

  cd tmp
  zip -r -X ../archive-${license}.zip *
  cd -
  rm -rf tmp
}

makeArchive byol
makeArchive hourly_pricing
