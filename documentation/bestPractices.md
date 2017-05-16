# Best Practices

The ARM templates aim to configure Couchbase according to our recommended best practices on Azure.

## Compute

A variety of compute types support premium storage.  Any such node will work well with Couchbase, though some may be more cost effective.  DS, FS and GS machines are the most commonly used.  While one core machines will deploy successfully we recommend machines with 4 or more cores for production applications.

In the near future, the templates will be moving to take advantage of VM Scale Sets (VMSS).

### Memory Allocation

Couchbase recommends allocating 85% of system memory to the database.  When using MDS this can be tuned between data, query, etc.  The templates currently allocate 50% for data and 15% for index.  This can be adjusted after deployment.

### Fault Tolerance and High Availability

Couchbase is a strongly consistent database.  Data lives on a primary node with some number of replicas.  For deployments in Azure we typically recommend one replica.  In the event of a failure, that replica will take over.  For most scenarios, the downed node will recover in a matter of minutes, obviating the need for additional replicas.

Azure does not currently have a concept of availability zones.  Instead, Azure provides Availability Sets that are made up of Fault Domains (FD) and Upgrade Domains (UD).  We recommend two FDs and 20 UDs.  FDs should then be mapped to the Couchbase concept of a Server Group.

Note that Azure currently deploys FDs and UDs across each other.  In the future Azure is introducing an option to align FDs to UDs to that each of the two FDs would have ten UDs.

## Storage

We recommend using Azure Premium Storage.  Ephemeral drives present a risk of data loss.  Standard Storage is based on spinning magnetic disks (HDD) and does not perform well enough for most database applications.

Premium Storage comes in three sizes - P10, P20 and P30.  P30 is the largest with 1TB of storage.  We find that 1TB is a good upper end for node density, so suggest a maximum of one P30 per node.

## Network

We recommend attaching a public IP to each node.  The public IP can be used to connect application drivers and replicate across geographies with XDCR.

We do not recommend VPN Gateways or Express Route given the complexity of configuration, poor performance and significant expense of those solutions.

The templates configure each Couchbase node with the public DNS.  Because the public DNS resolves to a NAT based IP, we recommend adding a record to /etc/hosts on each node to resolve its public DNS to 127.0.0.1.  That allows Couchbase to bind to the IP underlying the public DNS.

### Security

A number of steps are necessary to secure a Couchbase cluster.  These are currently handled in the template:
* Configure authentication for the administrator tool
* Create a network security group (NSG) to close off communication to ports that are not actively used

These are not:
* Enable SSL for traffic between nodes
* Enable authentication for connections to the database as well.  Note that the sample buckets are created with very permissive permissions.
