#!/bin/sh

RESOURCE_GROUP=$1

# CLI 1.0 commands
azure group create $RESOURCE_GROUP westus
azure group deployment create --template-file mainTemplate.json --parameters-file mainTemplateParameters.json $RESOURCE_GROUP

# CLI 2.0 commands -- these don't print much info, so we're not using them.
#az group create --name $RESOURCE_GROUP --location westus --output json
#az group deployment create --template-file mainTemplate.json --parameters @mainTemplateParameters.json --resource-group $RESOURCE_GROUP --output json
