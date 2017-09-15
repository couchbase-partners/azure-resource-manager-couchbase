#!/bin/sh

RESOURCE_GROUP=couchbaseManagedAppDefinition

az group create --name $RESOURCE_GROUP --location westcentralus
az managedapp definition create \
  -n couchbasedefinition \
  -l westcentralus \
  --resource-group $RESOURCE_GROUP \
  --lock-level readOnly \
  --display-name Couchbase \
  --description "Couchbase is the engagement database." \
  --authorizations "6588f057-f12f-43aa-9546-d545b00a6261:8e3af657-a8ff-443c-a75c-2fe8c4bcb635" \
  --package-file-uri "https://managedapp.blob.core.windows.net/app1/archive.zip" \
  --debug \
  --output json
