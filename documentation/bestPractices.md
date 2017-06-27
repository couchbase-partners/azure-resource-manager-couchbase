# Best Practices

The Azure Resource Manager (ARM) templates aim to configure Couchbase according to our recommended best practices on Azure.  Couchbase recommends ARM for all deployments on Azure.  We do not recommend Azure Service Manager (ASM), also known as Classic.

## Compute

A variety of compute types support premium storage.  Any such node will work well with Couchbase, though some may be more cost effective.  DS v2, FS and GS machines are the most commonly used.  While one core machines will deploy successfully, [we recommend machines with 4 or more cores](https://developer.couchbase.com/documentation/server/current/install/pre-install.html) for production applications.

We recommend using VMSS as it improves reliability and simplifies the addition and removal of nodes.

### Memory Allocation

Couchbase recommends allocating 85% of system memory to the database.  When using MDS this can be tuned between data, query, etc.  The templates currently allocate 50% for data and 15% for index.  This can be adjusted after deployment.

### Fault Tolerance and High Availability

Couchbase is a strongly consistent database.  Data lives on a primary node with some number of replicas.  For deployments in Azure we typically recommend one replica.  In the event of a failure, that replica will take over.  For most scenarios, the downed node will recover in a matter of minutes, obviating the need for additional replicas.

Azure does not currently have a concept of availability zones.  Instead, Azure provides Availability Sets that are made up of Fault Domains (FD) and Upgrade Domains (UD).  VM Scale Sets (VMSS) default to configuring 5 FDs, each with their own UD.  It's likely best practice will change with new Azure features in late 2017.

## Storage

We recommend using [Azure Premium Storage](https://docs.microsoft.com/en-us/azure/storage/storage-premium-storage) for data drives.  Ephemeral drives present a risk of data loss.  Standard Storage is based on spinning magnetic disks (HDD) and does not perform well enough for most database applications.  HDD is sufficient for OS disks.

Premium Storage comes in a variety of sizes.  We recommend a 1TB P30 drive as the upper end.  Large drives can lead to overly dense nodes that suffer from long rebuild times.  It's usually preferable to scale horizontally instead.

We strongly recommend using managed disks for both the OS and data disks.  The older Storage Account mechanism has a higher potential for bottlenecks and is more complex.

Microsoft recommends disabling Premium Storage caching for mixed read/write workloads like Couchbase.

## Network

There are three potential network setups in Azure that will support XDCR.  Those are detailed below.

### Public IPs
The Couchbase recommended setup is to attach a public IP to each node.  The public IP can be used to connect application drivers and replicate across geographies with XDCR.  

The templates configure each Couchbase node with the public DNS.  Because the public DNS resolves to a NAT based IP, we recommend adding a record to `/etc/hosts` on each node to resolve its public DNS to `127.0.0.1`.  That allows Couchbase to bind to the IP underlying the public DNS.

Traffic between public IPs in Azure is routed over the Azure backbone.  The backbone has a bandwidth in 100s-1000s G.  This means that traffic is limited by the network cap of a VM.  Larger VMs have a 10G network cap.

### VPN Gateways

An alternative is to use [VPN Gateways](https://azure.microsoft.com/en-us/pricing/details/vpn-gateway/).  The highest performance VPN Gateway has a 1.25G cap.  Note that this cap is for the entire deployment, not a single node.  As a result, traffic for most clusters will bottleneck on the gateway.  Latency is also an issue with this setup.

VPN Gateway setup is complex.  A gateway must be configured in each region and then unidirectional connections created between them.  When connecting multiple regions, the number of connections required will grow exponentially.

We do not recommend VPN Gateways given their complexity of configuration and poor performance.  It is our understanding that Microsoft intends VPN gateways for client to server connections, not high performance clustered applications like Couchbase.

### Express Route

An [Express Route](https://azure.microsoft.com/en-us/pricing/details/expressroute/) circuit is a leased line.  Microsoft works with providers like Verizon and Equinix to provide these lines.  The highest bandwidth line is 10G and costs $50,000 per month.  Not this is the bandwidth for the entire deployment, not a single node.

Express Route also has a setup time measured in weeks to months as it includes both manual setup tasks and contract negotiations.

Express Route traffic is routed through wherever the circuit exists.  So, if you are running a deployment with nodes in New York and San Francisco and your Express Route circuit is in London, all traffic will be routed across the Atlantic and back.

While Express Route is useful for on-prem/Azure hybrid solutions we do not recommend it for Azure to Azure XDCR communication.

## Security

The template automatically sets up a username and password for the Couchbase Web Administrator.  The template also configures a [Network Security Group (NSG)](https://docs.microsoft.com/en-us/azure/virtual-network/virtual-networks-nsg) that closes off unused ports.  This configuration can be further secured by specifying CIDR blocks to whitelist and blocking others.

Azure automatically configures disk encryption for Managed Disks that use Premium Storage.  More detail is available [here](https://azure.microsoft.com/en-us/blog/azure-managed-disks-sse).

The template does not currently configure SSL.  We recommend setting it up for production applications.

These templates open Sync Gateway access to the internet.  We typically recommend securing the admin interface for access from `127.0.0.1` only.  That can be done by editing the `/home/sync_gateway/sync_gateway.json` file.
