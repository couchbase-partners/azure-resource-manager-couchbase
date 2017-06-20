#!/bin/sh

RESOURCE_GROUP=$1

# CLI 1.0 commands
azure group create $RESOURCE_GROUP westus
azure group deployment create --template-uri https://raw.githubusercontent.com/couchbase-partners/azure-resource-manager-couchbase/master/simple/mainTemplate.json --parameters-file mainTemplateParameters.json $RESOURCE_GROUP couchbase
