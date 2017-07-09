# simple

## Important Note

This template uses two Azure Marketplace VMs.  To deploy in your Azure subscription you must first deploy the template once from the Azure Portal [here](https://azuremarketplace.microsoft.com/en-us/marketplace/apps/couchbase.couchbase-enterprise).

## Overview

This ARM template deploys a Couchbase Enterprise cluster to Azure.  This includes both [Couchbase Server](https://www.couchbase.com/products/server) and [Sync Gateway](https://developer.couchbase.com/documentation/mobile/current/guides/sync-gateway/index.html).  The template provisions a virtual network, a VMSS, Managed Disks with Premium Storage and public IPs with a DNS record per node.  It also sets up a network security group.

## Deployment

[deploy.sh](deploy.sh) has commands for both the 1 and 2 version of the Azure CLI.  [deploy.ps1](deploy.ps1) contains equivalent Azure PowerShell commands.  You can also deploy or inspect the template by clicking the buttons below:

<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fcouchbase-partners%2Fazure-resource-manager-couchbase%2Fmaster%2Fsimple%2FmainTemplate.json" target="_blank"><img src="http://azuredeploy.net/deploybutton.png"/></a>
<a href="http://armviz.io/#/?load=https%3A%2F%2Fraw.githubusercontent.com%2Fcouchbase-partners%2Fazure-resource-manager-couchbase%2Fmaster%2Fsimple%2FmainTemplate.json" target="_blank"><img src="http://armviz.io/visualizebutton.png"/></a>

Deployment typically takes less than five minutes.  When complete Couchbase administrator will be available on port 8091 of any Server node and Sync Gateway will be running on ports 4984 and 4985 of the Sync Gateway nodes.

The username and password entered for the deployment will be used for both the VM administrator credentials as well as the Couchbase administrator.
