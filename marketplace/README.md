# Marketplace

This template is used by the Couchbase Azure Marketplace offer.  It is not intended to be used outside the marketplace. [makeArchive.sh](makeArchive.sh) will build a zip file that can be uploaded to the publish portal.  This template depends on the [simple](../simple) template.  That is probably what you want to be using instead of this anyway.

# Testing the createUiDefinition

The [createUiDefinition.json](createUiDefinition.json) file can be tested by following this [link](https://portal.azure.com/?clientOptimizations=false#blade/Microsoft_Azure_Compute/CreateMultiVmWizardBlade/internal_bladeCallId/anything/internal_bladeCallerParams/%7B%22initialData%22:%7B%7D,%22providerConfig%22:%7B%22createUiDefinition%22:%22https%3A%2F%2Fraw.githubusercontent.com%2Fcouchbase-partners%2Fazure-resource-manager-couchbase%2Fmaster%2Fmarketplace%2FcreateUiDefinition.json%22%7D%7D)

# Build VM Image

This describes how we build the VM that the templates use.  Users should not need to do this.

## Documentation

Documentation on the process is here.  It is incomplete at best.
* https://docs.microsoft.com/en-us/azure/virtual-machines/virtual-machines-linux-capture-image
* https://azure.microsoft.com/en-us/documentation/articles/marketplace-publishing-vm-image-creation/
* https://azure.microsoft.com/en-us/documentation/articles/virtual-machines-linux-classic-create-upload-vhd/
* https://docs.microsoft.com/en-us/azure/virtual-machines/virtual-machines-linux-classic-capture-image

## Identify the VM Image to Use

You need the url or urlAlias for the image you want to use.  


~~az vm image list-skus --publish Canonical --location westus --offer UbuntuServer~~

use 

    az vm image list -f UbuntuServer

    Output:

    [
        {
            "offer": "UbuntuServer",
            "publisher": "Canonical",
            "sku": "18.04-LTS",
            "urn": "Canonical:UbuntuServer:18.04-LTS:latest",
            "urnAlias": "UbuntuLTS",
            "version": "latest"
        }
    ]

## Create a VM

Next you have to create a resource group,  Name does not matter.

    az group create --name <RESOURCE_GROUP_NAME> --location westus

Next you create a storage account.  Name does matter as the <STORAGE_ACCOUNT_NAME> must be lowercase alpha-numeric and will appear in the final url generated.

    az storage account create --sku Premium_LRS --resource-group <RESOURCE_GROUP_NAME> --location westus --name <STORAGE_ACCOUNT_NAME>

    Response:
    {- Finished ..
    "accessTier": "Hot",
    "allowBlobPublicAccess": null,
    "azureFilesIdentityBasedAuthentication": null,
    "blobRestoreStatus": null,
    "creationTime": "2020-12-18T18:23:36.616671+00:00",
    "customDomain": null,
    "enableHttpsTrafficOnly": true,
    "encryption": {
        "keySource": "Microsoft.Storage",
        "keyVaultProperties": null,
        "requireInfrastructureEncryption": null,
        "services": {
        "blob": {
            "enabled": true,
            "keyType": "Account",
            "lastEnabledTime": "2020-12-18T18:23:36.679163+00:00"
        },
        "file": {
            "enabled": true,
            "keyType": "Account",
            "lastEnabledTime": "2020-12-18T18:23:36.679163+00:00"
        },
        "queue": null,
        "table": null
        }
    },
    "failoverInProgress": null,
    "geoReplicationStats": null,
    "id": "/subscriptions/a384b1e1-47d0-4067-8d5e-8d9e16e650e4/resourceGroups/couchbase-ja-ubuntu-1804-setup/providers/Microsoft.Storage/storageAccounts/sajaubuntu1",
    "identity": null,
    "isHnsEnabled": null,
    "kind": "StorageV2",
    "largeFileSharesState": null,
    "lastGeoFailoverTime": null,
    "location": "westus",
    "minimumTlsVersion": null,
    "name": "sajaubuntu1",
    "networkRuleSet": {
        "bypass": "AzureServices",
        "defaultAction": "Allow",
        "ipRules": [],
        "virtualNetworkRules": []
    },
    "primaryEndpoints": {
        "blob": "https://sajaubuntu1.blob.core.windows.net/",
        "dfs": null,
        "file": null,
        "internetEndpoints": null,
        "microsoftEndpoints": null,
        "queue": null,
        "table": null,
        "web": "https://sajaubuntu1.z22.web.core.windows.net/"
    },
    "primaryLocation": "westus",
    "privateEndpointConnections": [],
    "provisioningState": "Succeeded",
    "resourceGroup": "couchbase-ja-ubuntu-1804-setup",
    "routingPreference": null,
    "secondaryEndpoints": null,
    "secondaryLocation": null,
    "sku": {
        "name": "Premium_LRS",
        "tier": "Premium"
    },
    "statusOfPrimary": "available",
    "statusOfSecondary": null,
    "tags": {},
    "type": "Microsoft.Storage/storageAccounts"
    }

The important part of this response is the primaryEndpoints.blob url as that will be used in the final URL

Last we create the <VM_NAME> using the Resource Group and Storage account and the Image URN

    az vm create --name <VM_NAME> --resource-group <RESOURCE_GROUP_NAME> --image <IMAGE_URN_FROM_PREVIOUS_STEP> --admin-username couchbase --use-unmanaged-disk --storage-account <STORAGE_ACCOUNT_NAME>

After creating the VM, you will get a response that contains the <publicIpAddress> value

    {- Finished ..
    "fqdns": "",
    "id": "/subscriptions/a384b1e1-47d0-4067-8d5e-8d9e16e650e4/resourceGroups/<RESOURCE_GROUP_NAME>/providers/Microsoft.Compute/virtualMachines/<VM_NAME>",
    "location": "westus",
    "macAddress": "00-22-48-09-5D-10",
    "powerState": "VM running",
    "privateIpAddress": "10.0.0.4",
    "publicIpAddress": "13.64.178.99",
    "resourceGroup": "<RESOURCE_GROUP_NAME>",
    "zones": ""
    }

use the publicIpAddress to SSH into the image using the command:

    ssh couchbase@<publicIpAddress>

## Clear the History

This command will clear out any user data that was placed on the image during the image creation

    sudo waagent -deprovision+user -force
    exit

## Deallocate and Generalize the VM Image

This removes the storage and generalizes the VM for usage in marketplace

    az vm deallocate --resource-group <RESOURCE_GROUP_NAME> --name <VM_NAME>
    az vm generalize --resource-group <RESOURCE_GROUP_NAME> --name <VM_NAME>

## Get the SAS URL

First off let's set the connection variable.

To generate certain values, we need a connection string value.  

    az storage account show-connection-string --resource-group <RESOURCE_GROUP_NAME> --name <STORAGE_ACCOUNT_NAME>

this outputs a connection string value you can use for other commands

    {
    "connectionString": "DefaultEndpointsProtocol=https;EndpointSuffix=core.windows.net;AccountName=<STORAGE_ACCOUNT_NAME>;AccountKey=ZE/ABJHpaA3pb1krzQ/C68y+1y/KDbSWyybU9j3OU6FH1vGvb6wDt0uTMQMaDbrTKbfuPNYuTL095uW/kcZprQ=="
    }

Now make sure the image is a vhd we use the connection string from above.

    azure storage blob list -c vhds -connection-string <connectionString>
    Response:
    [
    {
        "container": "vhds",
        "content": "",
        "deleted": null,
        "encryptedMetadata": null,
        "encryptionKeySha256": null,
        "encryptionScope": null,
        "isAppendBlobSealed": null,
        "isCurrentVersion": null,
        "metadata": {},
        "name": "osdisk_c1737cebed.vhd",
        "objectReplicationDestinationPolicy": null,
        "objectReplicationSourceProperties": null,
        "properties": {
        "appendBlobCommittedBlockCount": null,
        "blobTier": "P10",
        "blobTierChangeTime": null,
        "blobTierInferred": true,
        "blobType": "PageBlob",
        "contentLength": 32213303808,
        "contentRange": null,
        "contentSettings": {
            "cacheControl": null,
            "contentDisposition": null,
            "contentEncoding": null,
            "contentLanguage": null,
            "contentMd5": null,
            "contentType": "application/octet-stream"
        },
        "copy": {
            "completionTime": null,
            "destinationSnapshot": null,
            "id": null,
            "incrementalCopy": null,
            "progress": null,
            "source": null,
            "status": null,
            "statusDescription": null
        },
        "creationTime": "2020-12-18T19:02:02+00:00",
        "deletedTime": null,
        "etag": "0x8D8A387DEE66EBF",
        "lastModified": "2020-12-18T19:05:22+00:00",
        "lease": {
            "duration": "infinite",
            "state": "leased",
            "status": "locked"
        },
        "pageBlobSequenceNumber": 1,
        "pageRanges": null,
        "rehydrationStatus": null,
        "remainingRetentionDays": null,
        "serverEncrypted": true
        },
        "rehydratePriority": null,
        "requestServerEncrypted": null,
        "snapshot": null,
        "tagCount": null,
        "tags": null,
        "versionId": null
    }
    ]

The response is important as you will need the name property when assembling the final URL.

## We need to create a URL for the image.  

First we need to get the <SAS_SUFFIX>.  This controls access to the vsd file.

   az storage container generate-sas -n vhds --connection-string <connectionString> --start 2020-12-10 --expiry 2025-12-31 --permissions rl
   
   response:
   st=2020-12-10&se=2025-12-31&sp=rl&sv=2018-11-09&sr=c&sig=FhnhK3tm5Kntm6zD%2Bk7u79Oleobe8zDZaXe05fTyDds%3D


The Shared Access URL will be in this format:

<primaryEndpoints.blob>/vhds/<vsd.Name>?<SAS_SUFFIX>

To get the SAS URL, add the name of the os disk as follows.  You can find it early in your terminal session or in the [Portal](http://portal.azure.com).  Stick that value in a variable so we can use it later.

    url="https://sa34859435734.blob.core.windows.net/vhds/osdisk_587b3b1ebf.vhd?st=2018-01-16T08%3A00%3A00Z&se=2018-12-01T08%3A00%3A00Z&sp=rl&sv=2015-04-05&sr=c&sig=JVb2wVbD06veXnPNW58gBsbILNF1iFxFCtpjqyjXDyY%3D"

Make sure it works by running:

    wget $url

Once you can successfully get the image, proceed to the [Publisher Portal](https://cloudpartner.azure.com/#publisher).
