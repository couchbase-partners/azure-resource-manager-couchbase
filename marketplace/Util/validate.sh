#!/bin/bash
clear

startTime=$(date)

azure config mode arm
#RG's subscriptionId
#subscriptionId="f1766062-4c0b-4112-b926-2508fecc5bdf"
#Couchbase's subscriptionId
subscriptionId="a8cd090a-e76d-4f04-aa15-9f6bb65b68de"

azure account set $subscriptionId

storageAccountName="rgcb"
containerName="deployrg"

# Create Resource Group
newResourceGroupName="rgcb1234"
location="westus"

azure group create --name $newResourceGroupName --location $location

# Validate template
templateUri="https://$storageAccountName.blob.core.windows.net/$containerName/mainTemplate.json"
#parametersFiles="./Params/mainTemplate.mds.password.newVNet.parameters.json ./Params/mainTemplate.nonMds.password.newVNet.parameters.json ./Params/mainTemplate.gold.nonMds.password.newVNet.parameters.json"
#parametersFiles="./Params/mainTemplate.nonMds.password.newVNet.parameters.json"
parametersFiles="./Params/mainTemplate.gold.nonMds.password.newVNet.parameters.json"


for param in $parametersFiles
do
    echo "Testing $param"
    azure group template validate --resource-group $newResourceGroupName --template-uri $templateUri --parameters-file $param
done

endTime=$(date)

echo "Start time: $startTime"
echo "End time: $endTime"