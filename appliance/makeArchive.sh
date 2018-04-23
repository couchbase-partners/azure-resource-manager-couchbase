#!/usr/bin/env bash

rm archive.zip
mkdir tmp

cp mainTemplate.json tmp/mainTemplate.json
cp createUiDefinition.json tmp
cp ../extensions/* tmp

cd tmp
zip -r -X ../archive.zip *
cd -
rm -rf tmp
