# Marketplace

This template deploys a cluster to the Azure Marketplace.  It is not intended to be used outside the marketplace. [makeArchive.sh](makeArchive.sh) will build a zip file that can be uploaded to the publish portal.  This template depends on the [simple](../simple) template.

The [createUIDefinition.json](createUIDefinition.json) file can be tested by following this [link](https://portal.azure.com/?clientOptimizations=false#blade/Microsoft_Azure_Compute/CreateMultiVmWizardBlade/internal_bladeCallId/anything/internal_bladeCallerParams/%7B%22initialData%22:%7B%7D,%22providerConfig%22:%7B%22createUiDefinition%22:%22https%3A%2F%2Fraw.githubusercontent.com%2Fcouchbase-partners%2Fazure-resource-manager-couchbase%2Fmaster%2Fmarketplace%2FcreateUiDefinition.json%22%7D%7D)
