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
      "variables": {},
      "resources": [],
      "outputs": {}
    }

    username = parameters['username']
    password = parameters['password']

    for cluster in parameters['clusters']:
        template['resources'].append(generateCluster(cluster))

    file = open('generatedTemplate.json', 'w')
    file.write(json.dumps(template))
    file.close()

def generateCluster(cluster):
    resources = []
    clusterName = cluster['cluster']
    region = cluster['region']
    for group in cluster['groups']:
        resources.append(generateGroup(group))
    return resources

def generateGroup(group):
    groupName = group['group']
    nodeCount = group['nodeCount']
    nodeType = group['nodeType']
    diskSize = group['diskSize']
    services = group['services']

    resources=[]
    return resources

main()
