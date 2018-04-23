#!/usr/bin/env bash

rm archive.zip
mkdir tmp

cp mainTemplate.json tmp/applianceMainTemplate.json
cp applianceCreateUiDefinition.json tmp
cp ../extensions/* tmp

cd tmp
zip -r -X ../archive.zip *
cd -
rm -rf tmp
