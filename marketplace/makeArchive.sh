#!/usr/bin/env bash

# This script creates a zip of our archive to publish in the marketplace

mkdir tmp
cd tmp

cp ../../extensions/* ./
cp ../../simple/* ./

# Do this after and overwrite mainTemplate.json
cp ../mainTemplate.json ./
cp ../createUiDefinition.json ./

# Drop some files that don't need to be in the archive
rm README.md
rm deploy.sh
rm mainTemplateParameters.json

zip ../archive.zip *
cd -
rm -rf tmp
