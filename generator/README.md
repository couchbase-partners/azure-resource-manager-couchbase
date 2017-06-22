# Generator

## Extremely Important Note!

This is an ARM template generator for Couchbase.  It creates templates that leverage XDCR and MDS.  It doesn't work yet.

## Deployment

Creating a deployment is really simple.  Run the `deploy.sh` command with the name of a parameters file and the name of a resource group to create.  For instance:

    ./deploy.sh simple simpleresourcegroup

The generator will create an ARM template called `generatedTemplate.json` that matches the specs in the parameter file and deploy it to Azure.
