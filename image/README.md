# Build Image

This README describes how we build the VM that the templates use.  Users should not need to do this.

Documentation on the process is here.  It is incomplete at best.
* https://docs.microsoft.com/en-us/azure/virtual-machines/virtual-machines-linux-capture-image
* https://azure.microsoft.com/en-us/documentation/articles/marketplace-publishing-vm-image-creation/
* https://azure.microsoft.com/en-us/documentation/articles/virtual-machines-linux-classic-create-upload-vhd/
* https://docs.microsoft.com/en-us/azure/virtual-machines/virtual-machines-linux-classic-capture-image

## Identify the VM Image to Use

    az vm image list-skus --publish Canonical --location westus --offer UbuntuServer

## Create a VM

    az group create --name resourcegroup2 --location westus
    az storage account create --sku Premium_LRS --resource-group resourcegroup2 --location westus --name sa34859435734
    az vm create --name vm --resource-group resourcegroup2 --image Canonical:UbuntuServer:16.04.0-LTS:latest --admin-username couchbase --use-unmanaged-disk --storage-account sa34859435734

SSH into the image using the command:

    ssh couchbase@<publicIpAddress>

## Clear the history

    sudo waagent -deprovision+user -force
    exit

## Deallocate and Generalize the VM Image

    az vm deallocate --resource-group resourcegroup2 --name vm
    az vm generalize --resource-group resourcegroup2 --name vm

## Get the SAS URL

First lookup the name of your storage account in the portal.  In my case it was sa34859435734.  Now run this command to get a URL for the storage account.

    azure storage account connectionstring show <name of your storage account>
    con="DefaultEndpointsProtocol=https;AccountName=sa34859435734;AccountKey=<your key>"
    azure storage container list -c $con

Make sure the image is a vhd.

    azure storage blob list vhds -c $con

Now we need to create a URL for the image.  

The Publish Portal could potentially print an error: "The SAS URL start date (st) for the SAS URL should be one day before the current date in UTC, please ensure that the start date for SAS link is on or before 1/23/2017. Please ensure that the SAS URL is generated following the instructions available in the [help link](https://docs.microsoft.com/en-us/azure/marketplace-publishing/marketplace-publishing-vm-image-creation)."

    azure storage container sas create vhds rl 04/15/2017 -c $con --start 03/14/2017

The "Shared Access URL" should look like this:

    https://sa34859435734.blob.core.windows.net/vhds?st=2017-03-14T07%3A00%3A00Z&se=2017-04-15T07%3A00%3A00Z&sp=rl&sv=2015-04-05&sr=c&sig=pgA1z3OVEBYKiU9d%2Fyk7dQlKGjCm0mmPYzVeYJ6C7bc%3D

to get the sas url, add cli etc after vhds as follows:

https://sa34859435734.blob.core.windows.net/vhds/osdisk_clpJayvwMm.vhd?st=2017-03-14T07%3A00%3A00Z&se=2017-04-15T07%3A00%3A00Z&sp=rl&sv=2015-04-05&sr=c&sig=pgA1z3OVEBYKiU9d%2Fyk7dQlKGjCm0mmPYzVeYJ6C7bc%3D

Make sure it works by running:

    url="https://stosnrc0v8cyb40.blob.core.windows.net/vhds/cli4ba15cd2b2977623-os-1485296531848.vhd?st=2017-01-23T08%3A00%3A00Z&se=2017-02-24T08%3A00%3A00Z&sp=rl&sv=2015-04-05&sr=c&sig=woWQmN9YIm3jkWq8ZRzieUlX5SCigNDfOENzq7PzS7Y%3D"
    wget $url

Once you can successfully get the image, proceed to the publisher portal.
