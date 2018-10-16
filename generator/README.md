# generator

This is an ARM template generator for Couchbase.  It creates templates for different configurations including MDS.


## Important files

The assets needed for a public IP deployment (see the _ms section for private IP versions):

* parameters/granular.yaml - The majority of the variables needed to define a Couchbase cluster
* parameters/parameters.json - Defines software version, password and license type
* deploy.sh - Generate a template and deploy it

## _ms Templates

The _ms is used to generate a Private IP based Couchbase cluster.

The assets for the private IP deployment:

* deploy_ms.sh
* deploy_rally.sh
* granular_rally.yaml
* granular_ms.yaml
### Manual Steps

Manually/Externally create a Virtual Network in one of the following regions (all other resources should be created in the same region after this):

* Central US
* East US 2 (Preview)
* France Central
* North Europe
* Southeast Asia (Preview)
* West Europe
* West US 2
  
The deployment is locked down so it makes sense to create a subnet for admin resources like a jumpbox (optional) e.g. 10.0.0.192/28.

Create a subnet in the form of granular_rally.yaml clusters->clusterName - subnet, e.g. cluster1-subnet.  This can also be done in the rally phase and created via the template.

Use a range that is exclusive of your admin subnet from above like 10.0.0.0/25 or less (whatever is appropriate for your cluster)

### Rally phase

The rally phase involves creating a data node that initializes the cluster and is the point of creation for the rest of the cluster:

The rally phase is always the first step in creation of a Couchbase cluster using the generated ms templates.

Update granular_rally.yaml with clusters-> vnetName <to the name of your vnet>

`./deploy_rally.sh granular_rally <Resource Group> <region>`

This will create a deployment called 'RallyDeployment'

The deployment output 'Rally PrivateIP' is needed as an input for the non rally step.

### Non Rally phase

The non rally setup requires the 'Rally PrivateIP' from the rallyDeployment output field.

Enter the 'Rally PrivateIP' in granular_rally.yaml clusters-> rallyPrivateIP.

Update granular_ms.yaml with clusters-> vnetName <to the name of your vnet>

Now run:

`./deploy_rally.sh granular_rally <Resource Group> <region>`

This will create a deployment called NonRallyDeployment

The generator will create an ARM template called generatedTemplate.json that matches the specs in the parameter file and deploy it to Azure.
