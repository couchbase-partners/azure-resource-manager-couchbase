#!/bin/sh

###############################################################################
# Dependencies:                                                               #
# azure cli                                                                   #
# JQ                                                                          #
###############################################################################

###############################################################################
#  Parameters                                                                 #
#  -l :  Location                                                             #
#     usage: -l useast1                                                       #
#     purpose: Location based on az account list-locations                    #     
#  -p : Parameters                                                            #
#     usage:  -p mainTemplateParameterss.json                                 #
#     purpose:  Pass in a parameters file for the mainTemplate                #
#  -g : Resource Group                                                        #
#     usage: -g ja-test-1                                                     #
#     purpose: Specifies the name of the resource group to use. Will create   #
#              if not exists                                                  #
#  -n : Deployment Name                                                       #
#     usage: -n test_deployment_one                                           #
#     purposes: names the deployment in azure                                 #
###############################################################################

while getopts l:p:g:n: flag
do
    case "${flag}" in
        l) LOCATION=${OPTARG};;
        p) PARAMETERS=${OPTARG};;
        g) RESOURCE_GROUP=${OPTARG};;
        n) NAME=${OPTARG};;
        *) exit 1;;
    esac
done

echo "Location: ${LOCATION}"
echo "Parameters: ${PARAMETERS}"
echo "Resource Group: ${RESOURCE_GROUP}"
echo "Deployment Name: ${NAME}"

if [ -f "$PARAMETERS" ]; then
    echo "${PARAMETERS} exists"
else
    echo "Parameters file does not exist."
    exit 1
fi
location_exists=$(az account list-locations -o json | jq ".[] | .name" | grep ${LOCATION} -c)

if [ "$location_exists" = 0 ]; then
    echo "Invalid location."
    exit 1
fi

if [ "$(az group exists --name ${RESOURCE_GROUP})" = "true" ]; then
    echo "Group Exists, skipping creation"
else
    az group create --name $RESOURCE_GROUP --location $LOCATION --output table
fi

az deployment group create --verbose --template-file mainTemplate.json --parameters $PARAMETERS --resource-group $RESOURCE_GROUP --name $NAME --output table
