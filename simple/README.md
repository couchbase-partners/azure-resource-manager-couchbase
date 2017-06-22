# simple

This ARM template deploys a Couchbase Enterprise cluster to Azure.  The template provisions an availability set, vnet, and a variety of virtual machines each with their own managed disks and public IP addresses.  It also sets up a network security group.

## Deployment

[deploy.sh](deploy.sh) has commands for both the 1 and 2 version of the Azure CLI.  [deploy.ps1](deploy.ps1) contains equivalent Azure PowerShell commands.  You can also deploy or inspect the template by clicking the buttons below:

<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fcouchbase-partners%2Fazure-resource-manager-couchbase%2Fmaster%2Fsimple%2FmainTemplate.json" target="_blank"><img src="http://azuredeploy.net/deploybutton.png"/></a>
<a href="http://armviz.io/#/?load=https%3A%2F%2Fraw.githubusercontent.com%2Fcouchbase-partners%2Fazure-resource-manager-couchbase%2Fmaster%2Fsimple%2FmainTemplate.json" target="_blank"><img src="http://armviz.io/visualizebutton.png"/></a>

Deployment typically takes less than five minutes.  When complete Couchbase administrator will be available on port 8091 of any node.  The URL to access the admin on vm0 is output as the nodeAdminURL.  

The username and password entered for the deployment will be used for both the VM administrator credentials as well as the Couchbase administrator.
