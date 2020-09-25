# Couchbase Stack Deployment

## Usages:

To perform a deployment execute:

    ./deploy.sh -l <LOCATION> -p ./mainTemplateParameters.json -g <RESOURCE_GROUP_NAME> -n <DEPLOYMENT_NAME>

To remove a deployment execute:

    ./backout.sh -g <RESOURCE_GROUP_NAME>

optional -s parameter will prevent the removal of the resource group.  This operation can take a while to execute.

## Template Parameters

    /* The number of nodes to deploy */
    "serverNodeCount": {
      "type": "int",
      "defaultValue": 3
    },
    /* The size of the HDD */
    "serverDiskSize": {
      "type": "int",
      "defaultValue": 32
    },
    // The version of Couchbase to install.  In format X.Y.Z
    "serverVersion": {
      "type": "string",
      "defaultValue": "6.0.0"
    },
    // The size of the VM
    // Use:
    // az vm list-sizes --location <LOCATION>
    // To get list of vm sizes available in specified location
    "vmSize": {
      "type": "string",
      "defaultValue": "Standard_DS3_v2"
    },
    // The user name for the couchbase cluster and for the OS 
    "adminUsername": {
      "type": "string",
      "defaultValue": "couchbase"
    },
    // The password for the couchbase cluster and for the OS user
    "adminPassword": {
      "type": "securestring"
    },
    // The region/location of Azure the deployment is to be placed in
    "location": {
      "type": "string",
      "defaultValue": "[resourceGroup().location]"
    },
    // True ->  Each node will have a public IP address and can be accessed via the internet
    // False -> Each node will not have a public IP address
    "publicIpAddresses": {
      "type": "bool",
      "defaultValue": true
    },
    // The uri where to pull the custom scripts to be executed
    // Defaults to https://raw.githubusercontent.com/couchbase-partners/azure-resource-manager-couchbase/master/stack/
    "scriptsUri": {
      "type": "string",
      "defaultValue": "[variables('extensionUrl')]"
    }