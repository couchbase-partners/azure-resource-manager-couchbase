mkdir tmp
cd tmp

# Copy the files we're going to need
cp ../* ./

# Remove some that should not be in the archive
rm README.md
rm deploy.sh
rm mainTemplateParameters.json

# Zip it up and clean up after ourselves
zip ../archive.zip *
cd -
rm -rf tmp
