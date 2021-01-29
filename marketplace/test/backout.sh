#!/bin/sh

###############################################################################
# Dependencies:                                                               #
# azure cli                                                                   #
# JQ                                                                          #
###############################################################################

###############################################################################
#  Parameters                                                                 #
#  -g : Resource Group                                                        #
#     usage: -g ja-test-1                                                     #
#     purpose: Specifies the name of the resource group to use. Will create   #
#              if not exists                                                  #
#  -s : Save Resource Group                                                   #
#     usage: -s                                                               #
#     purposes: Specifies whether resource group should be maintained         #
###############################################################################

###############################################################################
#  WARNING;  THIS WILL DELETE ALL RESOURCES WITHIN A RESOURCE GROUP           #
###############################################################################

while getopts g:s flag
do
    case "${flag}" in
        g) RESOURCE_GROUP=${OPTARG};;
        s) SAVE=1;;
        *) exit 1;;
    esac
done

echo "Resource Group: ${RESOURCE_GROUP}"
echo "Save Resource Group: ${SAVE}"


if [ "$SAVE" -eq "1" ]; then
    echo "Save was passed, deleting resources but leaving group."
    az deployment group create --verbose --template-file ResourceGroupCleanup.template.json --resource-group $RESOURCE_GROUP --mode Complete
    exit 0
fi

az group delete --name $RESOURCE_GROUP --yes
