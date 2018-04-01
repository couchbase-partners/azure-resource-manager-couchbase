#!/bin/sh

PARAMETERS_FILE=$1
RESOURCE_GROUP=$2

# create generatedTemplate.json
python deployment.py parameters/${PARAMETERS_FILE}.yaml

az group create --name $RESOURCE_GROUP --location westus --output table
az group deployment create --verbose --template-file generatedTemplate.json --resource-group $RESOURCE_GROUP --output table
