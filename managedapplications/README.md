# Managed Applications
This template is an [Azure Managed Application](https://azure.microsoft.com/en-us/blog/azure-managed-applications/) that uses the [simple](../simple) Couchbase ARM template.

# Process

Note: This process is changing soon.

1. run makeArchive.sh
2. create a resource group to store the definition
3. create a storage account to store the definition
4. create a container with access level blob
5. upload the definition to that blob
6. copy the url
7. paste the url into [deployDefinition.sh](deployDefinition.sh)
8. run deployDefinition.sh
9. copy the id
10. paste resource ID for couchbasedefinition into mainTemplate.json
11. in the portal create a new managed application.  This needs to be in West Central US.
12. try deploying it.  That may fail.  If so, remake the archive and upload it to storage and redeploy the app definition.
13. now retry deploying an instance of the managed app
