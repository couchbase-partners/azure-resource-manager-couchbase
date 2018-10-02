import sys
import yaml
import json

debugStr = "\n--- DEBUG: \n-- "
def main():
    filename= sys.argv[1]
    print('Using user file: ' + filename)

    with open(filename, 'r') as stream:
        parameters = yaml.load(stream)

    print('User file parameters: ' + str(parameters))
    clusters = parameters['clusters']
    # testString = clusters[0]
    # print(debugStr + '\n*** clusters: ' + str(testString))
    # print(debugStr + '\n*** cluster services: ' + str(testString['clusterMeta'][0]['services']))

    template={
        "$schema": "https://schema.management.azure.com/schemas/2015-01-01/deploymentTemplate.json#",
        "contentVersion": "1.0.0.0",
        "parameters": generateParameters(clusters),
        "variables": {
            "extensionUrl": "https://raw.githubusercontent.com/couchbase-partners/azure-resource-manager-couchbase/master/extensions/",
            "uniqueString": "[uniquestring(resourceGroup().id, deployment().name)]",
            "serverPubIP": "[concat(resourceGroup().id, '/providers/Microsoft.Compute/virtualMachineScaleSets/server/virtualMachines/0/networkInterfaces/nic/ipConfigurations/ipconfig/publicIPAddresses/public')]",
            "syncPubIP": "[concat(resourceGroup().id, '/providers/Microsoft.Compute/virtualMachineScaleSets/syncgateway/virtualMachines/0/networkInterfaces/nic/ipConfigurations/ipconfig/publicIPAddresses/public')]"
        },
        "resources": [],
        "outputs": generateOutputs(parameters['clusters'])
    }
    resources = []
    for cluster in parameters['clusters']:
        resources.append(generateCluster(cluster))

    print(debugStr + " final resources " + str(resources))
    template['resources'] = [i for i in resources[0] if i] # TODO:  This is being built sloppily need to fix eventually, trimming out {} and pulling out the correct item of the list with in the list
    
    file = open('generatedTemplate.json', 'w')
    file.write(json.dumps(template, sort_keys=False, indent=2, separators=(',', ': ')) + '\n')
    file.close()

def generateParameters(clusters):
    parameters={
        "serverVersion": {
            "type": "string"
        },
        "syncGatewayVersion": {
            "type": "string"
        },
        "adminUsername": {
            "type": "securestring"
        },
        "adminPassword": {
            "type": "securestring"
        },
        "license": {
            "type": "string"
        }
    }
    return parameters

def generateCluster(cluster):
    resources = []
    if cluster['clusterName'] is not None:
        clusterName = cluster['clusterName'] + "-"
    else:
        clusterName = ""

    vnetName = cluster['vnetName']
    if vnetName is None:
        createVnet = True
        vnetName = clusterName + 'vnet'
    else:
        createVnet = False
        
    vnetAddrPrefix = cluster['vnetAddrPrefix']
    print(debugStr + ' vnetAddrPrefix ' + vnetAddrPrefix)
    region = cluster['clusterRegion']

    resources.append(dict(generatedGUID()))
    resources.append(dict(generateNetworkSecurityGroups(clusterName, region)))
    clusterMeta = cluster['clusterMeta']
    print(debugStr + ' clusterMeta ' + str(clusterMeta))
    subnetPrefixes = {}
    subnetPostfix = '-subnet'
    for group in cluster['clusterMeta'] or {}:

        groupName = group['group'] + subnetPostfix 
        subnetPrefixes[groupName] = group['subnetAddrPrefix']
        if not createVnet and group['nodeCount'] > 0:
            resources.append(dict(generateSubnet(vnetName, groupName, group['subnetAddrPrefix'])))

    if createVnet:
           
        resources.append(dict(generateVirtualNetwork(region, vnetName, vnetAddrPrefix, subnetPrefixes)))
        
    # print(debugStr + 'clusterRegion ' + str(cluster['clusterRegion']))
   # i=3
    print(debugStr + ' clusterMeta ' + str(clusterMeta))
    rallyGroup = ""

    for group in cluster['clusterMeta'] or {}:

        groupName = group['group']

        if 'data' in group['services'] and rallyGroup ==  "":
            groupName = "rallyGroup000" 

        resources.append(dict(generateGroup(clusterName, region, group, vnetName, createVnet, groupName + subnetPostfix, groupName)))
       #  print(debugStr + "this round of resources ... " + json.dumps(resources, sort_keys=True, indent=4, separators=(',', ': '))) 

   #  print(debugStr + "return of generateCluster " + json.dumps(resources, sort_keys=True, indent=4, separators=(',', ': ')))
    return resources

def generatedGUID():
    guid={
        "apiVersion": "2017-05-10",
        "type": "Microsoft.Resources/deployments",
        "name": "[concat(resourceGroup().name, resourceGroup().location, 'pid-bac94ebc-cc78-4dbd-bc39-4b5433e1014c')]",
        "properties": {
            "mode": "Incremental",
            "template": {
                "$schema": "https://schema.management.azure.com/schemas/2015-01-01/deploymentTemplate.json#",
                "contentVersion": "1.0.0.0",
                "resources": []
            }
        }
    }
    return guid

def generateNetworkSecurityGroups(clusterName, region):
    itemName = clusterName + "nsg"
    networkSecurityGroups={
        "apiVersion": "2016-06-01",
        "type": "Microsoft.Network/networkSecurityGroups",
        "name": itemName,
        "location": region,
        "properties": {
            "securityRules": [
                {
                    "name": "SSH",
                    "properties": {
                        "description": "SSH",
                        "protocol": "Tcp",
                        "sourcePortRange": "*",
                        "destinationPortRange": "22",
                        "sourceAddressPrefix": "Internet",
                        "destinationAddressPrefix": "*",
                        "access": "Allow",
                        "priority": 100,
                        "direction": "Inbound"
                    }
                },
                {
                    "name": "ErlangPortMapper",
                    "properties": {
                        "description": "Erlang Port Mapper (epmd)",
                        "protocol": "Tcp",
                        "sourcePortRange": "*",
                        "destinationPortRange": "4369",
                        "sourceAddressPrefix": "Internet",
                        "destinationAddressPrefix": "*",
                        "access": "Allow",
                        "priority": 101,
                        "direction": "Inbound"
                    }
                },
                {
                    "name": "SyncGateway",
                    "properties": {
                        "description": "Sync Gateway",
                        "protocol": "Tcp",
                        "sourcePortRange": "*",
                        "destinationPortRange": "4984-4985",
                        "sourceAddressPrefix": "Internet",
                        "destinationAddressPrefix": "*",
                        "access": "Allow",
                        "priority": 102,
                        "direction": "Inbound"
                    }
                },
                {
                    "name": "Server",
                    "properties": {
                        "description": "Server",
                        "protocol": "Tcp",
                        "sourcePortRange": "*",
                        "destinationPortRange": "8091-8096",
                        "sourceAddressPrefix": "Internet",
                        "destinationAddressPrefix": "*",
                        "access": "Allow",
                        "priority": 103,
                        "direction": "Inbound"
                    }
                },
                {
                    "name": "Index",
                    "properties": {
                        "description": "Index",
                        "protocol": "Tcp",
                        "sourcePortRange": "*",
                        "destinationPortRange": "9100-9105",
                        "sourceAddressPrefix": "Internet",
                        "destinationAddressPrefix": "*",
                        "access": "Allow",
                        "priority": 104,
                        "direction": "Inbound"
                    }
                },
                {
                    "name": "Analytics",
                    "properties": {
                        "description": "Analytics",
                        "protocol": "Tcp",
                        "sourcePortRange": "*",
                        "destinationPortRange": "9110-9122",
                        "sourceAddressPrefix": "Internet",
                        "destinationAddressPrefix": "*",
                        "access": "Allow",
                        "priority": 105,
                        "direction": "Inbound"
                    }
                },
                {
                    "name": "Internal",
                    "properties": {
                        "description": "Internal",
                        "protocol": "Tcp",
                        "sourcePortRange": "*",
                        "destinationPortRange": "9998-9999",
                        "sourceAddressPrefix": "Internet",
                        "destinationAddressPrefix": "*",
                        "access": "Allow",
                        "priority": 106,
                        "direction": "Inbound"
                    }
                },
                {
                    "name": "XDCR",
                    "properties": {
                        "description": "XDCR",
                        "protocol": "Tcp",
                        "sourcePortRange": "*",
                        "destinationPortRange": "11207-11215",
                        "sourceAddressPrefix": "Internet",
                        "destinationAddressPrefix": "*",
                        "access": "Allow",
                        "priority": 107,
                        "direction": "Inbound"
                    }
                },
                {
                    "name": "SSL",
                    "properties": {
                        "description": "SSL",
                        "protocol": "Tcp",
                        "sourcePortRange": "*",
                        "destinationPortRange": "18091-18096",
                        "sourceAddressPrefix": "Internet",
                        "destinationAddressPrefix": "*",
                        "access": "Allow",
                        "priority": 108,
                        "direction": "Inbound"
                    }
                },
                {
                    "name": "NodeDataExchange",
                    "properties": {
                        "description": "Node data exchange",
                        "protocol": "Tcp",
                        "sourcePortRange": "*",
                        "destinationPortRange": "21100-21299",
                        "sourceAddressPrefix": "Internet",
                        "destinationAddressPrefix": "*",
                        "access": "Allow",
                        "priority": 109,
                        "direction": "Inbound"
                    }
                }
            ]
        }
    }
    return networkSecurityGroups

def generateSubnet(vnetName, subnetName, subnetAddrPrefix):

    subnet = {
        "apiVersion": "2018-04-01",
        "type": "Microsoft.Network/virtualNetworks/subnets",
        "name": vnetName + '/' +  subnetName,
        "location": "[resourceGroup().location]",
        "properties": {
            "addressPrefix": subnetAddrPrefix
        } 
    }
    return subnet

def generateVirtualNetwork(region, vnetName, vnetAddrPrefix, subnetPrefixes):
    virtualNetwork={
        "name": vnetName,
        "type": "Microsoft.Network/virtualNetworks",
        "apiVersion": "2015-06-15",
        "location": region,
        "dependsOn": [
            "Microsoft.Network/networkSecurityGroups/networksecuritygroups"  
        ],
        "properties": {
            "addressSpace": {
                "addressPrefixes": [vnetAddrPrefix]
            },
            "subnets": []
        }
    }
    for key, value in subnetPrefixes.iteritems():
        virtualNetwork['subnets'].append({
            "name": key,
            "properties": {
                "addressPrefix": value,
                "networkSecurityGroup": {
                    "id": "[resourceId('Microsoft.Network/networkSecurityGroups', 'networksecuritygroups')]"
                }
            }
        })
    print(debugStr + "generateVirtualNetwork "  + json.dumps(virtualNetwork, sort_keys=False, indent=2, separators=(',', ': ')))
    return virtualNetwork

def generateGroup(clusterName, region, group, vnetName, createVnet, subnetName, groupName):
    #print('DEBUG: generateGroup ***\n ***\n ' + str(group))
    
    services = group['services']
    resources={}
    if ('syncGateway'.lower() in (service.lower() for service in services) or 'sgw'.lower() in (service.lower() for service in services)):
        resources = generateSyncGateway(region, group, vnetName, createVnet, subnetName)
    else:
        resources = generateServer(region, group, vnetName, createVnet, subnetName, groupName)

    return resources

def generateServer(region, group, vnetName, createVnet, subnetName, groupName):
    nodeCount = group['nodeCount']
    if nodeCount < 1:
        return {} 
    diskSize = group['diskSize']
    nodeType = group['nodeType']
    services = group['services']
    servicesList = ' '.join(services)
    server={
        "type": "Microsoft.Compute/virtualMachineScaleSets",
        "name": groupName + "-SVRScaleSet",
        "location": region,
        "apiVersion": "2017-03-30",
        "dependsOn": [
            "Microsoft.Network/virtualNetworks/" + vnetName
        ],
        "plan": {
            "publisher": "couchbase",
            "product": "couchbase-server-enterprise",
            "name": "[parameters('license')]"
        },
        "sku": {
            "name": nodeType,
            "tier": "Standard",
            "capacity": nodeCount
        },
        "properties": {
            "overprovision": False,
            "upgradePolicy": {
                "mode": "Manual"
            },
            "virtualMachineProfile": {
                "storageProfile": {
                    "osDisk": {
                        "createOption": "FromImage"
                    },
                    "imageReference": {
                        "publisher": "couchbase",
                        "offer": "couchbase-server-enterprise",
                        "sku": "[parameters('license')]",
                        "version": "latest"
                    },
                    "dataDisks": [
                        {
                            "lun": 0,
                            "createOption": "Empty",
                            "managedDisk": {
                                "storageAccountType": "Premium_LRS"
                            },
                            "caching": "None",
                            "diskSizeGB": diskSize
                        }
                    ]
                },
                "osProfile": {
                    "computerNamePrefix": "server",
                    "adminUsername": "[parameters('adminUsername')]",
                    "adminPassword": "[parameters('adminPassword')]"
                },
                "networkProfile": {
                    "networkInterfaceConfigurations": [
                        {
                            "name": "nic",
                            "properties": {
                                "primary": True,
                                "ipConfigurations": [
                                    {
                                        "name": "ipconfig",
                                        "properties": {
                                            "subnet": {
                                                "id": "[concat(resourceId('Microsoft.Network/virtualNetworks/', '" + vnetName + "'), '/subnets/" + subnetName + "')]"
                                            },
                                            "publicipaddressconfiguration": {
                                                "name": "public",
                                                "properties": {
                                                    "idleTimeoutInMinutes": 30,
                                                    "dnsSettings": {
                                                        "domainNameLabel": "[concat('server-', '" + groupName + "', variables('uniqueString'))]"
                                                    }
                                                }
                                            }
                                        }
                                    }
                                ]
                            }
                        }
                    ]
                },
                "extensionProfile": {
                    "extensions": [
                        {
                            "name": "extension",
                            "properties": {
                                "publisher": "Microsoft.Azure.Extensions",
                                "type": "CustomScript",
                                "typeHandlerVersion": "2.0",
                                "autoUpgradeMinorVersion": True,
                                "settings": {
                                    "fileUris": [
                                        "[concat(variables('extensionUrl'), 'server.sh')]",
                                        "[concat(variables('extensionUrl'), 'util.sh')]"
                                    ]
                                },
                                "protectedSettings": {
                                    "commandToExecute": "[concat('bash server.sh ', parameters('serverVersion'), ' ', parameters('adminUsername'), ' ', parameters('adminPassword'), ' ', variables('uniqueString'), ' ', '" + region + "', ' ', '" + servicesList + "', ' ', '" + groupName + "', ' ', 'rallyGroup000')]" 
                                }
                            }
                        }
                    ]
                }
            }
        }
    }
    if not createVnet:
        del server['dependsOn']

    print (debugStr + 'generateServer \n *- \n *--- ' + json.dumps(server, sort_keys=True, indent=4, separators=(',', ': ')))
    return server

def generateSyncGateway(region, group, vnetName, createVnet, subnetName):

    nodeCount = group['nodeCount']
    if nodeCount < 1:
        return {}

    nodeType = group['nodeType']
    groupName = group['group']
    syncGateway={
        "type": "Microsoft.Compute/virtualMachineScaleSets",
        "name": groupName + "-SGWScaleSet",
        "location": region,
        "apiVersion": "2017-03-30",
        "dependsOn": [
            "Microsoft.Network/virtualNetworks/" + vnetName
        ],
        "plan": {
            "publisher": "couchbase",
            "product": "couchbase-sync-gateway-enterprise",
            "name": "[parameters('license')]"
        },
        "sku": {
            "name": nodeType,
            "tier": "Standard",
            "capacity": nodeCount
        },
        "properties": {
            "overprovision": False,
            "upgradePolicy": {
                "mode": "Manual"
            },
            "virtualMachineProfile": {
                "storageProfile": {
                    "osDisk": {
                        "createOption": "FromImage"
                    },
                    "imageReference": {
                    "publisher": "couchbase",
                    "offer": "couchbase-sync-gateway-enterprise",
                    "sku": "[parameters('license')]",
                    "version": "latest"
                    }
                },
                "osProfile": {
                    "computerNamePrefix": "syncgateway",
                    "adminUsername": "[parameters('adminUsername')]",
                    "adminPassword": "[parameters('adminPassword')]"
                },
                "networkProfile": {
                    "networkInterfaceConfigurations": [
                        {
                            "name": "nic",
                            "properties": {
                                "primary": True,
                                "ipConfigurations": [
                                    {
                                        "name": "ipconfig",
                                        "properties": {
                                            "subnet": {
                                                "id": "[concat(resourceId('Microsoft.Network/virtualNetworks/', '" + vnetName + "'), '/subnets/" + subnetName + "')]"
                                            },
                                            "publicipaddressconfiguration": {
                                                "name": "public",
                                                "properties": {
                                                    "idleTimeoutInMinutes": 30,
                                                    "dnsSettings": {
                                                        "domainNameLabel": "[concat('syncgateway-', variables('uniqueString'))]"
                                                    }
                                                }
                                            }
                                        }
                                    }
                                ]
                            }
                        }
                    ]
                },
                "extensionProfile": {
                    "extensions": [
                        {
                            "name": "extension",
                            "properties": {
                                "publisher": "Microsoft.Azure.Extensions",
                                "type": "CustomScript",
                                "typeHandlerVersion": "2.0",
                                "autoUpgradeMinorVersion": True,
                                "settings": {
                                    "fileUris": [
                                        "[concat(variables('extensionUrl'), 'syncGateway.sh')]",
                                        "[concat(variables('extensionUrl'), 'util.sh')]"
                                    ]
                                },
                                "protectedSettings": {
                                    "commandToExecute": "[concat('bash syncGateway.sh ', parameters('syncGatewayVersion'), ' ', " + region + ")]"
                                }
                            }
                        }
                    ]
                }
            }
        }
    }
    if not createVnet:
        del syncGateway['dependsOn']

    return syncGateway

def generateOutputs(clusters):
    outputs={}

    for cluster in clusters:
        clusterName = cluster['clusterName']
        if cluster['clusterName'] is not None:
            clusterName = cluster['clusterName'] + "-"
        else:
            clusterName = ""

        print(debugStr + 'ClusterName ' + clusterName)
        #region = cluster['clusterMeta']['region']

        outputs[clusterName + 'serverAdminURL']={
            "type": "string",
            "value": "[concat('http://', reference(variables('serverPubIP'), '2017-03-30').dnsSettings.fqdn, ':8091')]"
        }

        outputs[clusterName + 'syncGatewayAdminURL']={
            "type": "string",
            "value": "[concat('http://', reference(variables('syncPubIP'), '2017-03-30').dnsSettings.fqdn, ':8091')]"
        }
    print('\n------\n generateOutputs ' + str(outputs))
    return outputs

main()
