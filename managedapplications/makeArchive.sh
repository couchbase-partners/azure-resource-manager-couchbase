#!/usr/bin/env bash

# This script creates a zip of our template to publish in the marketplace

rm archive.zip
mkdir tmp
cd tmp

cp ../mainTemplate.json ./
cp ../applianceMainTemplate.json ./
cp ../createUiDefinition.json ./
cp ../applianceCreateUiDefinition.json ./

cp ../../extensions/* ./

zip ../archive.zip *
cd -
rm -rf tmp
