#!/usr/bin/env bash

rm archive.zip
mkdir tmp

cp mainTemplate.json tmp
cp applianceMainTemplate.json tmp
cp createUiDefinition.json tmp
cp applianceCreateUiDefinition.json tmp

zip -r -X archive.zip tmp
rm -rf tmp
