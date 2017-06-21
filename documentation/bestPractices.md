# Best Practices

The ARM templates aim to configure Couchbase according to our recommended best practices on Azure.

## Compute

A variety of compute types support premium storage.  Any such node will work well with Couchbase, though some may be more cost effective.  DS, FS and GS machines are the most commonly used.  While one core machines will deploy successfully [we recommend machines with 4 or more cores](https://developer.couchbase.com/documentation/server/current/install/pre-install.html) for production applications.

We recommend using VMSS as it improves reliability and simplifies the addition and removal of nodes.

### Memory Allocation

Couchbase recommends allocating 85% of system memory to the database.  When using MDS this can be tuned between data, query, etc.  The templates currently allocate 50% for data and 15% for index.  This can be adjusted after deployment.

### Fault Tolerance and High Availability

Couchbase is a strongly consistent database.  Data lives on a primary node with some number of replicas.  For deployments in Azure we typically recommend one replica.  In the event of a failure, that replica will take over.  For most scenarios, the downed node will recover in a matter of minutes, obviating the need for additional replicas.

Azure does not currently have a concept of availability zones.  Instead, Azure provides Availability Sets that are made up of Fault Domains (FD) and Upgrade Domains (UD).  VMSS default to configuring 5 FDs, each with their own UD.  It's likely best practice will change with new Azure features in late 2017.

## Storage

We recommend using [Azure Premium Storage](https://docs.microsoft.com/en-us/azure/storage/storage-premium-storage) for data drives.  Ephemeral drives present a risk of data loss.  Standard Storage is based on spinning magnetic disks (HDD) and does not perform well enough for most database applications.  HDD is sufficient for OS disks.

Premium Storage comes in a variety of sizes.  We recommend a 1TB P30 drive as the upper end.  Large drives can lead to overly dense nodes that suffer from long rebuild times.  It's usually preferable to scale horizontally instead.

## Network

We recommend attaching a public IP to each node.  The public IP can be used to connect application drivers and replicate across geographies with XDCR.

We do not recommend VPN Gateways or Express Route given the complexity of configuration, poor performance and significant expense of those solutions.

The templates configure each Couchbase node with the public DNS.  Because the public DNS resolves to a NAT based IP, we recommend adding a record to /etc/hosts on each node to resolve its public DNS to 127.0.0.1.  That allows Couchbase to bind to the IP underlying the public DNS.

### Security

The template automatically sets up a username and password for the Couchbase Web Administrator.  The template also configures a [Network Security Group (NSG)](https://docs.microsoft.com/en-us/azure/virtual-network/virtual-networks-nsg) that closes off unused ports.  If you are not using XDCR and do not need to connect drivers remotely, we recommend changing the NSG settings to "VirtualNetwork" for Couchbase ports other than 8091 and 4984.

Azure automatically configures disk encryption.  More detail is available [here](https://azure.microsoft.com/en-us/blog/azure-managed-disks-sse).

The template does not currently configure SSL.  We recommend setting it up for production applications.
