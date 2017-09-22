#!/usr/bin/env bash

rm archive.zip
mkdir tmp

cp main-template.json tmp
cp ../extensions/* tmp

zip -r -X archive.zip tmp
rm -rf tmp
