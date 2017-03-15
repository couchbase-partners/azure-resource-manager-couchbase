# Build Image

This README describes how we build the VM that the templates use.  Users should not need to do this.

Documentation on the process is here.  The first link is by far the best.
* https://docs.microsoft.com/en-us/azure/virtual-machines/virtual-machines-linux-capture-image
* https://azure.microsoft.com/en-us/documentation/articles/marketplace-publishing-vm-image-creation/
* https://azure.microsoft.com/en-us/documentation/articles/virtual-machines-linux-classic-create-upload-vhd/
* https://docs.microsoft.com/en-us/azure/virtual-machines/virtual-machines-linux-classic-capture-image

## Identify the VM Image to Use

    az vm image list-skus --publish Canonical --location westus --offer UbuntuServer

## Create a VM

    az group create --name resourcegroup --location westus
    az vm create --name vm --resource-group resourcegroup --image Canonical:UbuntuServer:16.04.0-LTS:latest --admin-username couchbase

SSH into the image using the command:

    ssh couchbase@<publicIpAddress>

## Clear the history

    sudo waagent -deprovision+user -force
    exit

## Deallocate, Generalize and Create the VM Image

    az vm deallocate --resource-group resourcegroup --name vm
    az vm generalize --resource-group resourcegroup --name vm

## Get the SAS URL

In the portal click on the disk for the image and select "export."  Select a longer expiration time.  One month is 30*24*60*60=2592000.  Then click "Generate URL."

When complete copy the SAS URL.  Test downloading the URL using wget.  Once you can successfully get the image, proceed to the publisher portal.
