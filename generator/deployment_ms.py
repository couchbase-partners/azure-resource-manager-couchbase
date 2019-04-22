import sys
import yaml
import json

#constants
debugStr = "\n--- DEBUG: \n-- "
rallyTag = 'rally' #from rally yaml
rallyConstant = "rallygroup"
VMSSPostfix = "-SVRScaleSet"
VMSS_SGW_Postfix =  "-SGWScaleSet"
vnetPostfix = "-vnet"
nsgPostfix = "-nsg"
availabilitySetPostfix = "-AS"
outputRallyPrivateIP = False
SGWGroupConstant = "syncGateway"

def main():
    filename = sys.argv[1]
    print('Using user file: ' + filename)

    with open(filename, 'r') as stream:
        parameters = yaml.load(stream)

   # print(debugStr + 'User file parameters: ' + str(parameters))
    clusters = parameters['clusters']

    resources = []
    for cluster in parameters['clusters']:
        resources.append(generateCluster(cluster))

    template = {
        "$schema": "https://schema.management.azure.com/schemas/2015-01-01/deploymentTemplate.json#",
        "contentVersion": "1.0.0.0",
        "parameters": generateParameters(clusters),
        "variables": {
            "extensionUrl": "https://raw.githubusercontent.com/couchbase-partners/azure-resource-manager-couchbase/master/extensions/",
            #"uniqueString": "[uniquestring(resourceGroup().id, resourceGroup().location)]",
            "rallyPrivateIP": "[concat(resourceGroup().id, '/providers/Microsoft.Compute/virtualMachineScaleSets/', '" + rallyConstant + VMSSPostfix + "', '/virtualMachines/0/networkInterfaces/nic/ipConfigurations/ipconfig')]",
         #   "serverPubIP": "[concat(resourceGroup().id, '/providers/Microsoft.Compute/virtualMachineScaleSets/', '" + rallyConstant + VMSSPostfix + "',  '/virtualMachines/0/networkInterfaces/nic/ipConfigurations/ipconfig/publicIPAddresses/public')]",
            "syncPubIP": "[concat(resourceGroup().id, '/providers/Microsoft.Compute/virtualMachineScaleSets/" + SGWGroupConstant + VMSS_SGW_Postfix + "/virtualMachines/0/networkInterfaces/nic/ipConfigurations/ipconfig/publicIPAddresses/public')]"
        },
        "resources": [],
        "outputs": generateOutputs(parameters['clusters'])
    }


    #print(debugStr + " final resources " + str(resources))
    template['resources'] = [i for i in resources[0] if i] # TODO:  This is being built sloppily need to fix eventually, trimming out {} and pulling out the correct item of the list with in the list
   
    file = open('generatedTemplate.json', 'w')
    file.write(json.dumps(template, sort_keys=False, indent=2, separators=(',', ': ')) + '\n')
    file.close()

def generateParameters(clusters):

    parameters = {
        "uniqueString": {
            "type": "string"
        },
        "prefix": {
            "type": "string"
        },
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
        },
        "region": {
            "type": "string",
            "defaultValue": "centralus",
            "allowedValues": [
                "centralus",
                "westus2",
                "eastus2"
            ] 
        }
    }
    return parameters

def generateCluster(cluster):

    resources = []
    if cluster['clusterName'] is not None:
        # clusterName = cluster['clusterName'] + "-"
        clusterName = cluster['clusterName']
    else:
        clusterName = ""


    noVnetControlString = 'eert12231ss'
    vnetName = cluster.get('vnetName', noVnetControlString)
    if vnetName == noVnetControlString:
        createVnet = True
        vnetName = clusterName + vnetPostfix
        #print(debugStr + 'Creating Vnet ' + vnetName)
        vnetAddrPrefix = cluster['vnetAddrPrefix']
        #print(debugStr + ' vnetAddrPrefix ' + vnetAddrPrefix)
    else:
        createVnet = False
        
    region = cluster['clusterRegion']
    nsgName = clusterName + nsgPostfix
  #  resources.append(dict(generateDNSZones(vnetName)))
    #resources.append(dict(generateGUID()))
    resources.append(dict(generateNetworkSecurityGroups(nsgName, region)))
    clusterMeta = cluster['clusterMeta']
    #print(debugStr + ' clusterMeta ' + str(clusterMeta))
    subnetPrefixes = {}
    subnetPostfix = '-subnet'

    rallyGroup = ""
    rallyPrivateIP = cluster.get('rallyPrivateIP', "")
    for group in clusterMeta or {}:

        #The first nodes with the data service will be the rally node.   The rally node initalizes the cluster and is used for api/cli commands 
        #All nodes need to know this rallynode.  The VMSS that includes the rally node is the Rally scaleset

        groupName = group['VMSSgroup']

        #groupServices = group['services']
        # if 'data' in groupServices and rallyGroup ==  "":
        #     rallyGroup = rallyConstant + groupServices 
        #     groupName = rallyGroup

        if groupName == rallyTag:
            group['nodeCount'] = 1 #There can only be one rally so ignore the yaml value
            rallyGroup = rallyConstant
            groupName = rallyGroup
            #outputRallyPrivateIP = True

        elif rallyPrivateIP == "" and not (groupName.lower() == SGWGroupConstant.lower()):
                print("ERROR: rallyPrivateIP is mandatory! clusters->rallyPrivateIP in the yaml") 
                exit (1)

        resources.append(dict(generateGroup(clusterName, region, group, vnetName, createVnet, clusterName + subnetPostfix, groupName, rallyPrivateIP)))

        #build Subnet list
        #this is line is for a single subnet across the cluster
        
       # if rallyPrivateIP != "":
       #     subnetPrefixes[clusterName + subnetPostfix] =  cluster['subnetAddrPrefix']

        #below for a subnet per group
        # if group['nodeCount'] > 0:
        #     appGroupName = groupName + subnetPostfix 
        #     subnetPrefixes[appGroupName] = group['subnetAddrPrefix']

          #  if not createVnet:
          #      resources.append(dict(generateSubnet(vnetName, nsgName, appGroupName, group['subnetAddrPrefix'])))

#    if not createVnet: 
#        resources.append(dict(generateSubnet(vnetName, nsgName, clusterName + subnetPostfix, cluster['subnetAddrPrefix'])))

    if createVnet:
        resources.append(dict(generateVirtualNetwork(region, vnetName, nsgName, vnetAddrPrefix, subnetPrefixes))) #TODO: Make it one subnet even on vnet creation
       #  print(debugStr + "this round of resources ... " + json.dumps(resources, sort_keys=True, indent=4, separators=(',', ': '))) 

   #  print(debugStr + "return of generateCluster " + json.dumps(resources, sort_keys=True, indent=4, separators=(',', ': ')))
    return resources

def generateDNSZones(vnetName):
    dnsZones = {
        "location": "global",
        "type": "Microsoft.Network/dnszones",
        "zoneType": "Private", 
        "name": "couchbase.local",
        "registrationVirtualNetworks": [
            {
                "name": "Microsoft.Network/virtualNetworks/" + vnetName
            }
        ],
        "resolutionVirtualNetworks": [],
        "tags": {}
    }

def generateGUID():
    guid={
        "apiVersion": "2017-05-10",
        "type": "Microsoft.Resources/deployments",
        "name": "[concat('pid-couchbase-2018-4dbd-', parameters('uniqueString'))]",
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

def generateNetworkSecurityGroups(nsgName, region):

    networkSecurityGroups={
        "apiVersion": "2018-08-01",
        "type": "Microsoft.Network/networkSecurityGroups",
        "name": nsgName,
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
                        "sourceAddressPrefix": "VirtualNetwork",
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
                        "sourceAddressPrefix": "VirtualNetwork",
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
                        "sourceAddressPrefix": "VirtualNetwork",
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
                        "sourceAddressPrefix": "VirtualNetwork",
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
                        "sourceAddressPrefix": "VirtualNetwork",
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
                        "sourceAddressPrefix": "VirtualNetwork",
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
                        "sourceAddressPrefix": "VirtualNetwork",
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
                        "sourceAddressPrefix": "VirtualNetwork",
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

def generateSubnet(vnetName, nsgName, subnetName, subnetAddrPrefix):

    subnet = {
        "apiVersion": "2018-04-01",
        "type": "Microsoft.Network/virtualNetworks/subnets",
        "name": vnetName + '/' +  subnetName,
        "location": "[resourceGroup().location]",
        "properties": {
            "addressPrefix": subnetAddrPrefix,
            "networkSecurityGroup": {
                    "id": "[resourceId('Microsoft.Network/networkSecurityGroups', '" + nsgName + "')]"
            }
        } 
    }
    return subnet

def generateVirtualNetwork(region, vnetName, nsgName, vnetAddrPrefix, subnetPrefixes):
    virtualNetwork={
        "name": vnetName,
        "type": "Microsoft.Network/virtualNetworks",
        "apiVersion": "2015-06-15",
        "location": region,
        "dependsOn": [
            "Microsoft.Network/networkSecurityGroups/" + nsgName  
        ],
        "properties": {
            "addressSpace": {
                "addressPrefixes": [vnetAddrPrefix]
            },
            "subnets": []
        }
    }
    for key, value in subnetPrefixes.iteritems():
        virtualNetwork['properties']['subnets'].append({
            "name": key,
            "properties": {
                "addressPrefix": value,
                "networkSecurityGroup": {
                    "id": "[resourceId('Microsoft.Network/networkSecurityGroups', '" + nsgName + "')]"
                }
            }
        })
    #print(debugStr + "generateVirtualNetwork "  + json.dumps(virtualNetwork, sort_keys=False, indent=2, separators=(',', ': ')))
    return virtualNetwork

def generateAvailabiltySet(clusterName, groupName, numVM, region):
    
    availabilitySet = {
            "apiVersion": "2018-06-01",
            "type": "Microsoft.Compute/availabilitySets",
            "name": clusterName + '-' + groupName + availabilitySetPostfix,
            "location": region,
            "properties": {
                "platformUpdateDomainCount": 2,
                "platformFaultDomainCount": 5,
                "virtualMachines": []
            },
            "tags": {},
            "sku": {
                "name": "[parameters('sku')]"
            }
    }
    return availabilitySet

def generateGroup(clusterName, region, group, vnetName, createVnet, subnetName, groupName, rallyPrivateIP):
    #print('DEBUG: generateGroup ***\n ***\n ' + str(group))
    
    services = group['services']
    resources={}
    if ('syncGateway'.lower() in (service.lower() for service in services) or 'sgw'.lower() in (service.lower() for service in services)):
        resources = generateSyncGateway(region, group, vnetName, createVnet, subnetName)
    else:
        resources = generateServer(region, group, vnetName, createVnet, subnetName, groupName, rallyPrivateIP)

    return resources

def generateServer(region, group, vnetName, createVnet, subnetName, groupName, rallyPrivateIP):
    nodeCount = group['nodeCount']
    if nodeCount < 1:
        return {} 
    diskSize = group['diskSize']
    nodeType = group['nodeType']
    services = group['services']
    servicesList = ','.join(services)
    cbServerGroupName = group['CBServerGroup']
    server={
        "type": "Microsoft.Compute/virtualMachineScaleSets",
        "name": groupName + VMSSPostfix,
        "location": region,
        "apiVersion": "2018-06-01",
        "zones": [ "1", "2", "3"],
        "dependsOn": [
            "Microsoft.Network/virtualNetworks/" + vnetName,
            "Microsoft.Network/subnets/" + subnetName
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
            "singlePlacementGroup": False,
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
                                            }
                                            # "publicipaddressconfiguration": {
                                            #     "name": "public",
                                            #     "properties": {
                                            #         "idleTimeoutInMinutes": 30,
                                            #         "dnsSettings": {
                                            #             "domainNameLabel": "[concat('server-', '" + groupName + "', parameters('uniqueString'))]"
                                            #         }
                                            #     }
                                            # }
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
                                        "[concat(variables('extensionUrl'), 'server_generator.sh')]",
                                        "[concat(variables('extensionUrl'), 'util.sh')]"
                                    ]
                                },
                                "protectedSettings": {
                                    "commandToExecute": "[concat('bash server_generator.sh ', parameters('serverVersion'), ' ', parameters('adminUsername'), ' ', parameters('adminPassword'), ' ', '" + servicesList + "', ' ', '" + groupName + "', ' ', '" + cbServerGroupName + "', ' ', '" + rallyPrivateIP + "')]" 
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

  #  print (debugStr + 'generateServer \n *- \n *--- ' + json.dumps(server, sort_keys=True, indent=4, separators=(',', ': ')))
    return server

def generateSyncGateway(region, group, vnetName, createVnet, subnetName):

    nodeCount = group['nodeCount']
    if nodeCount < 1:
        return {}

    nodeType = group['nodeType']
    groupName = group['VMSSgroup']
    syncGateway={
        "type": "Microsoft.Compute/virtualMachineScaleSets",
        "name": SGWGroupConstant + VMSS_SGW_Postfix,
        "location": region,
        "apiVersion": "2018-06-01",
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
                                                        "domainNameLabel": "[concat('syncgateway-', parameters('uniqueString'))]"
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
                                    "commandToExecute": "[concat('bash syncGateway.sh ', parameters('syncGatewayVersion'))]"
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

        outputs['Rally PrivateIp'] = {
            "type": "string",
            "value": "[reference(variables('rallyPrivateIP'), '2016-09-01').privateIPAddress]"
        }
        # outputs[clusterName + 'buildHosts']={
        #    "type": "string",
        #    "value": "[concat('.server | syncgateway -', '<group>', parameters('uniqueString'), ' .location ', ' .couchbase-ms.local')]"
        # } 
        #print(debugStr + 'ClusterName ' + clusterName)
        #region = cluster['clusterMeta']['region']

#        outputs[clusterName + 'serverAdminURL']={
#            "type": "string",
#            "value": "[concat('http://', reference(variables('serverPubIP'), '2017-03-30').dnsSettings.fqdn, ':8091')]"
#        }

        if any(('syncGateway' in group['services'] and group['nodeCount'] > 0) for group in cluster['clusterMeta']):
            outputs[clusterName + 'syncGatewayAdminURL']={
                "type": "string",
                "value": "[concat('http://', reference(variables('syncPubIP'), '2017-03-30').dnsSettings.fqdn, ':4985/_admin/')]"
            }

    #print(debugStr + ' generateOutputs ' + str(outputs))
    return outputs

main()
