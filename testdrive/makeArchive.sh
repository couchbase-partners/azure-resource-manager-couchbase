#!/usr/bin/env bash

# Currently the Test Drive doesn't support archives in any meaningful way.  Instead only a single ARM template can be in the file.  No sub templates or scripts are allowed.

rm archive.zip
mkdir tmp

cp main-template.json tmp

cd tmp
zip -r -X ../archive.zip *
cd -
rm -rf tmp
