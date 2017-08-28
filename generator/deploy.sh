#!/bin/sh

PARAMETERS_FILE=$1
RESOURCE_GROUP=$2

# create generatedTemplate.json
python deployment.py parameters/${PARAMETERS_FILE}.yaml
