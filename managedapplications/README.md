# Managed Applications
This template is an [Azure Managed Application](https://azure.microsoft.com/en-us/blog/azure-managed-applications/) that uses the [simple](../simple) Couchbase ARM template.

# IMPORTANT NOTE
This doesn't work yet!

# Process...

1. run makeArchive.sh
2. create a resource group to store the definition
3. create a storage account to store the definition
4. create a container with access level blob
5. upload the definition to that blob
6. copy the url
7. paste the url into [deployDefinition.sh](deployDefinition.sh)
8. run deployDefinition.sh
9. paste resource ID for couchbasedefinition into mainTemplate.json
