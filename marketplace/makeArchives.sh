#!/usr/bin/env bash

function makeArchive()
{
  license=$1
  rm archive-${license}.zip
  mkdir tmp

  cp mainTemplate-${license}.json tmp/mainTemplate.json
  cp createUiDefinition.json tmp
  cp ../scripts/* tmp

  cd tmp
  zip -r -X ../archive-${license}.zip *
  cd -
  rm -rf tmp
}

makeArchive byol_2019
makeArchive hourly_pricing_mar19
