#!/bin/sh

PARAMETERS_FILE=$1
RESOURCE_GROUP=$2

# create generatedTemplate.json
python deployment.py parameters.${PARAMETERS_FILE}.yaml

# Azure CLI 1.0 commands
#azure group create $RESOURCE_GROUP westus
#azure group deployment create --template-file generatedTemplate.json $RESOURCE_GROUP couchbase
