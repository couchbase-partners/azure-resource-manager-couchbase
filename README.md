# Important Note

This repo uses a VMSS feature that is in preview currently.  Please contact ben.lackey@couchbase.com for assistance.  We're expecting GA shortly at which point this will become a non-issue.

Note, if you haven't deployed within the Azure Portal, you'll need to do that to use these templates.  Otherwise you'll get an error like this:

    error:   MarketplacePurchaseEligibilityFailed : Marketplace purchase eligibilty check returned errors. See inner errors for details.

# azure-resource-manager-couchbase

These are Azure Resource Manager (ARM) templates that install Couchbase Enterprise.  [simple](simple) is probably the best starting point.  [marketplace](marketplace) is the template used in the Couchbase Azure Marketplace offer. [generator](generator) is a template generator for advanced configurations.

Some best practices are covered [here](documentation/bestPractices.md).

Useful links are [here](https://github.com/couchbase-partners/links/blob/master/microsoft.md).
