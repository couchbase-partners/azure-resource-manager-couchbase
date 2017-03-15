$resourceGroup = "deployment"
$deployment = "couchbase" + $resourceGroup

New-AzureRmResourceGroup -Name $resourceGroup -Location westus
New-AzureRmResourceGroupDeployment -Name $deployment -ResourceGroupName $resourceGroup -TemplateFile mainTemplate.json -TemplateParameterFile mainTemplateParameters.json
