#!/bin/sh

RESOURCE_GROUP=$1

# CLI 1.0 commands
azure group create $RESOURCE_GROUP westus
azure group deployment create --template-file mainTemplate.json --parameters-file mainTemplateParameters.json $RESOURCE_GROUP

# CLI 2.0 commands
#az group create --name $RESOURCE_GROUP --location westus
#az group deployment create --verbose --template-file mainTemplate.json --parameters @mainTemplateParameters.json --resource-group $RESOURCE_GROUP
