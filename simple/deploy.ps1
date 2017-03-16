param (
    [string]$resourceGroupParam = "deployment"
 )

$resourceGroup = $resourceGroupParam
$deployment = "couchbase" + $resourceGroup
$templateUri = "https://raw.githubusercontent.com/rafaelgodinho/azure-resource-manager-couchbase/master/simple/mainTemplate.json"

New-AzureRmResourceGroup -Name $resourceGroup -Location westus
New-AzureRmResourceGroupDeployment -Name $deployment -ResourceGroupName $resourceGroup -TemplateUri $templateUri -TemplateParameterFile mainTemplateParameters.json