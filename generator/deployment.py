import sys
import yaml
import json

def main():
    filename=sys.argv[1]
    print('Using parameter file: ' + filename)

    with open(filename, 'r') as stream:
        parameters = yaml.load(stream)

    print('Parameters: ' + str(parameters))

    template={
        "$schema": "https://schema.management.azure.com/schemas/2015-01-01/deploymentTemplate.json#",
        "contentVersion": "1.0.0.0",
        "parameters": {},
        "variables": {
            "extensionUrl": "https://raw.githubusercontent.com/couchbase-partners/azure-resource-manager-couchbase/master/extensions/",
            "uniqueString": "[uniquestring(resourceGroup().id, deployment().name)]"
        },
        "resources": [],
        "outputs": generateOutputs()
    }

    license = parameters['license']
    username = parameters['username']
    password = parameters['password']

    for cluster in parameters['clusters']:
        template['resources']+=generateCluster(cluster)

    file = open('generatedTemplate.json', 'w')
    file.write(json.dumps(template, sort_keys=True, indent=4, separators=(',', ': ')) + '\n')
    file.close()

def generateCluster(cluster):
    resources = []
    clusterName = cluster['cluster']
    region = cluster['region']

    resources.append(generateNetworkSecurityGroups(clusterName, region))
    resources.append(generateVirtualNetwork(clusterName, region))
    for group in cluster['groups']:
        resources+=generateGroup(group)
    return resources

def generateNetworkSecurityGroups(clusterName, region):
    networkSecurityGroups={
        "apiVersion": "2016-06-01",
        "type": "Microsoft.Network/networkSecurityGroups",
        "name": "networksecuritygroups-" + clusterName,
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
        "name": "vnet-" + clusterName,
        "type": "Microsoft.Network/virtualNetworks",
        "apiVersion": "2015-06-15",
        "location": region,
        "dependsOn": [
            "Microsoft.Network/networkSecurityGroups/networksecuritygroups-" + clusterName
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
                            "id": "[resourceId('Microsoft.Network/networkSecurityGroups', 'networksecuritygroups')]"
                        }
                    }
                }
            ]
        }
    }
    return virtualNetwork

def generateGroup(group):
    groupName = group['group']
    nodeCount = group['nodeCount']
    nodeType = group['nodeType']
    diskSize = group['diskSize']
    services = group['services']

    resources={}
    return resources

def generateOutputs():
    outputs={
        "serverAdminURL": {
            "type": "string",
            "value": "[concat('http://vm0.server-', variables('uniqueString'), '.', parameters('location'), '.cloudapp.azure.com:8091')]"
        },
        "syncGatewayAdminURL": {
            "type": "string",
            "value": "[concat('http://vm0.syncgateway-', variables('uniqueString'), '.', parameters('location'), '.cloudapp.azure.com:4985/_admin/')]"
        }
    }
    return outputs

main()
