######### This needs cleaned up!!!!



Clear-Host

$resourceGroupName = "rgcb"
$resourceGroupNameDeploy = "rgcb97"
$deploymentName = $resourceGroupName + "maindeploy"
$templateFile = "mainTemplate.json"
$parameterFile = "mainTemplate-new-vnet-parameters.json"
#$parameterFile = "mainTemplate-existing-vnet-parameters.json"
#$parameterFile = "mainTemplate-parameters-sshKey.json"
$storageAccountName = $resourceGroupName
$storageContainer = "deployrg"

Select-AzureRmSubscription -SubscriptionId "f1766062-4c0b-4112-b926-2508fecc5bdf"

$storageAccountKey = (Get-AzureRmStorageAccountKey -Name $storageAccountName -ResourceGroupName $resourceGroupName).Value[0]
$storageAccountCtx = New-AzureStorageContext -StorageAccountName $storageAccountName -StorageAccountKey $storageAccountKey

$container = Get-AzureStorageContainer -Name $storageContainer -Context $storageAccountCtx -ErrorAction SilentlyContinue

if ($container -eq $null)
{
    New-AzureStorageContainer -Name $storageContainer -Context $storageAccountCtx -Permission Blob
}

Set-AzureStorageBlobContent -File "vm.json" -Container $storageContainer -Context $storageAccountCtx -Force
Set-AzureStorageBlobContent -File "storage.json" -Container $storageContainer -Context $storageAccountCtx -Force
Set-AzureStorageBlobContent -File "role.json" -Container $storageContainer -Context $storageAccountCtx -Force
Set-AzureStorageBlobContent -File "network.json" -Container $storageContainer -Context $storageAccountCtx -Force
Set-AzureStorageBlobContent -File "mainTemplate.json" -Container $storageContainer -Context $storageAccountCtx -Force
Set-AzureStorageBlobContent -File "vnet_new.json" -Container $storageContainer -Context $storageAccountCtx -Force
Set-AzureStorageBlobContent -File "vnet_existing.json" -Container $storageContainer -Context $storageAccountCtx -Force
Set-AzureStorageBlobContent -File "UI\createUiDefinition.json" -Container $storageContainer -Context $storageAccountCtx -Force

#New-AzureRmResourceGroup -Name $resourceGroupNameDeploy -Location westus -Force
#New-AzureRmResourceGroupDeployment -Name $deploymentName -ResourceGroupName $resourceGroupNameDeploy -TemplateFile $templateFile -TemplateParameterFile $parameterFile

#Remove-AzureRmResourceGroup -Name $resourceGroupNameDeploy -Force

#UI test URL
#https://portal.azure.com/#blade/Microsoft_Azure_Compute/CreateMultiVmWizardBlade/internal_bladeCallId/anything/internal_bladeCallerParams/{"initialData":{},"providerConfig":{"createUiDefinition":"https%3A%2F%2Frgcb.blob.core.windows.net%2Fdeployrg%2FcreateUiDefinition.json"}}
#GitHub UI Url
#https://portal.azure.com/#blade/Microsoft_Azure_Compute/CreateMultiVmWizardBlade/internal_bladeCallId/anything/internal_bladeCallerParams/{"initialData":{},"providerConfig":{"createUiDefinition":"https%3A%2F%2Fraw.githubusercontent.com%2Frafaelgodinho%2FCouchbase-Azure-Marketplace%2Fmaster%2FUI%2FcreateUiDefinition.json"}}
