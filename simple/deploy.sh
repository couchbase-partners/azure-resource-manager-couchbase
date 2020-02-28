#!/bin/sh

RESOURCE_GROUP=$1
REGION=${2-'westus'}
az group create --name $RESOURCE_GROUP --location $REGION --output table
az group deployment create --verbose --template-file mainTemplate.json --parameters @mainTemplateParameters.json --resource-group $RESOURCE_GROUP --output table