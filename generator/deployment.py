import sys
import yaml
import json

def main():
    filename=sys.argv[1]
    print('Using parameter file: ' + filename)

    with open(filename, 'r') as stream:
        parameters = yaml.load(stream)

    print('Parameters: ' + str(parameters))

    license = parameters['license']
    username = parameters['username']
    password = parameters['password']

    template={
        "$schema": "https://schema.management.azure.com/schemas/2015-01-01/deploymentTemplate.json#",
        "contentVersion": "1.0.0.0",
        "parameters": {},
        "variables": {
            "extensionUrl": "https://raw.githubusercontent.com/couchbase-partners/azure-resource-manager-couchbase/master/extensions/",
            "uniqueString": "[uniquestring(resourceGroup().id, deployment().name)]"
        },
        "resources": [],
        "outputs": generateOutputs(parameters['clusters'])
    }

    for cluster in parameters['clusters']:
        template['resources']+=generateCluster(license, username, password, cluster)

    file = open('generatedTemplate.json', 'w')
    file.write(json.dumps(template, sort_keys=True, indent=4, separators=(',', ': ')) + '\n')
    file.close()

def generateCluster(license, username, password, cluster):
    resources = []
    clusterName = cluster['cluster']
    region = cluster['region']

    resources.append(generateNetworkSecurityGroups(clusterName, region))
    resources.append(generateVirtualNetwork(clusterName, region))
    for group in cluster['groups']:
        resources+=generateGroup(license, username, password, clusterName, region, group)

    return resources

def generateNetworkSecurityGroups(clusterName, region):
    networkSecurityGroups={
        "apiVersion": "2016-06-01",
        "type": "Microsoft.Network/networkSecurityGroups",
        "name": clusterName,
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
                        "description": "Erlang Port Mapper ( epmd )",
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
                        "destinationPortRange": "8091-8094",
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
                    "name": "Internal",
                    "properties": {
                        "description": "Internal",
                        "protocol": "Tcp",
                        "sourcePortRange": "*",
                        "destinationPortRange": "9998-9999",
                        "sourceAddressPrefix": "Internet",
                        "destinationAddressPrefix": "*",
                        "access": "Allow",
                        "priority": 105,
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
                        "priority": 106,
                        "direction": "Inbound"
                    }
                },
                {
                    "name": "SSL",
                    "properties": {
                        "description": "SSL",
                        "protocol": "Tcp",
                        "sourcePortRange": "*",
                        "destinationPortRange": "18091-18093",
                        "sourceAddressPrefix": "Internet",
                        "destinationAddressPrefix": "*",
                        "access": "Allow",
                        "priority": 107,
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
                        "priority": 108,
                        "direction": "Inbound"
                    }
                }
            ]
        }
    }
    return networkSecurityGroups

def generateVirtualNetwork(clusterName, region):
    virtualNetwork={
        "name": clusterName,
        "type": "Microsoft.Network/virtualNetworks",
        "apiVersion": "2015-06-15",
        "location": region,
        "dependsOn": [
            "Microsoft.Network/networkSecurityGroups/" + clusterName
        ],
        "properties": {
            "addressSpace": {
                "addressPrefixes": ["10.0.0.0/8"]
            },
            "subnets": [
                {
                    "name": "subnet",
                    "properties": {
                        "addressPrefix": "10.0.0.0/16",
                        "networkSecurityGroup": {
                            "id": "[resourceId('Microsoft.Network/networkSecurityGroups', '" + clusterName + "')]"
                        }
                    }
                }
            ]
        }
    }
    return virtualNetwork

def generateGroup(license, username, password, clusterName, region, group):
    groupName = group['group']
    nodeCount = group['nodeCount']
    nodeType = group['nodeType']
    diskSize = group['diskSize']
    services = group['services']

    resources={}
    return resources

def generateServer():
    server={
        "type": "Microsoft.Compute/virtualMachineScaleSets",
        "name": "server",
        "location": "[parameters('location')]",
        "apiVersion": "2017-03-30",
        "dependsOn": [
            "Microsoft.Network/virtualNetworks/vnet"
        ],
        "plan": {
            "publisher": "couchbase",
            "product": "couchbase-server-enterprise",
            "name": "[parameters('license')]"
        },
        "sku": {
            "name": "[parameters('vmSize')]",
            "tier": "Standard",
            "capacity": "[parameters('serverNodeCount')]"
        },
        "properties": {
            "overprovision": false,
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
                        "lun": "0",
                        "createOption": "empty",
                        "managedDisk": {
                            "storageAccountType": "Premium_LRS"
                        },
                        "caching": "None",
                        "diskSizeGB": "[parameters('serverDiskSize')]"
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
        "primary": "true",
        "ipConfigurations": [
        {
        "name": "ipconfig",
        "properties": {
        "subnet": {
        "id": "[concat(resourceId('Microsoft.Network/virtualNetworks/', 'vnet'), '/subnets/subnet')]"
        },
        "publicipaddressconfiguration": {
        "name": "public",
        "properties": {
        "idleTimeoutInMinutes": 30,
        "dnsSettings": {
        "domainNameLabel": "[concat('server-', variables('uniqueString'))]"
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
        "autoUpgradeMinorVersion": true,
        "settings": {
        "fileUris": [
        "[concat(variables('extensionUrl'), 'server.sh')]",
        "[concat(variables('extensionUrl'), 'util.sh')]"
        ],
        "commandToExecute": "[concat('bash server.sh ', parameters('serverVersion'), ' ', parameters('adminUsername'), ' ', parameters('adminPassword'), ' ', variables('uniqueString'), ' ', parameters('location'))]"
        }
        }
        }
        ]
        }
        }
        }
    }
    return server

def generateSyncGateway:
    {
    "type": "Microsoft.Compute/virtualMachineScaleSets",
    "name": "syncgateway",
    "location": "[parameters('location')]",
    "apiVersion": "2017-03-30",
    "dependsOn": [
    "Microsoft.Network/virtualNetworks/vnet"
    ],
    "plan": {
    "publisher": "couchbase",
    "product": "couchbase-sync-gateway-enterprise",
    "name": "[parameters('license')]"
    },
    "sku": {
    "name": "[parameters('vmSize')]",
    "tier": "Standard",
    "capacity": "[parameters('syncGatewayNodeCount')]"
    },
    "properties": {
    "overprovision": false,
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
    "primary": "true",
    "ipConfigurations": [
    {
    "name": "ipconfig",
    "properties": {
    "subnet": {
    "id": "[concat(resourceId('Microsoft.Network/virtualNetworks/', 'vnet'), '/subnets/subnet')]"
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
    "autoUpgradeMinorVersion": true,
    "settings": {
    "fileUris": [
    "[concat(variables('extensionUrl'), 'syncGateway.sh')]",
    "[concat(variables('extensionUrl'), 'util.sh')]"
    ],
    "commandToExecute": "[concat('bash syncGateway.sh ', parameters('syncGatewayVersion'))]"
    }
    }
    }
    ]
    }
    }
    }
    }

def generateOutputs(clusters):
    outputs={}

    for cluster in clusters:
        clusterName = cluster['cluster']
        region = cluster['region']

        outputs[clusterName + '-serverAdminURL']={
            "type": "string",
            "value": "[concat('http://vm0.server-', variables('uniqueString'), '." + region + ".cloudapp.azure.com:8091')]"
        }

        outputs[clusterName + '-syncGatewayAdminURL']={
            "type": "string",
            "value": "[concat('http://vm0.syncgateway-', variables('uniqueString'), '." + region + ".cloudapp.azure.com:4985/_admin/')]"
        }

    return outputs

main()
