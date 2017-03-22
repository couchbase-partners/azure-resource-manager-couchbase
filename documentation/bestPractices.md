# Best Practices

The ARM templates provided in this repo configure Couchbase according to our recommended best practices on Azure.

## Compute

A variety of compute types support premium storage.  Any such node will work well with Couchbase, though some may be more cost effective.  DS, FS and GS machines are the most commonly used.

### Memory Allocation

Q: We're currently doing 50% for data and 15% for index.  Need a good solution here.

### Fault Tolerance and High Availability

Q: Need to come up with a solution for FD/UD mapping

## Storage

We recommend using Azure Premium Storage.  Ephemeral drives present a risk of data loss.  Standard Storage is based on spinning magnetic disks (HDD) and does not perform well enough for most database applications.

Q: Given that Couchbase prefers RAM will a P10 be sufficient or do we need other options?

Q: With managed storage do we need to provision multiple data disks for optimal IO?

Q: If everything is in memory do we really need to use premium or can we use standard instead?

## Network

We recommend attaching a public IP to each node.  The public IP can be used to connect application drivers and replicate across geographies with XDCR.

We do not recommend VPN Gateways or Express Route given the complexity of configuration, poor performance and significant expense of those solutions.

Q: Do nodes need to bind to DNS/PIP somehow?  They don't seem to like the NAT.

### Security

A number of steps are necessary to secure a Couchbase cluster:
* Configure authentication for the administrator tool
* Enable SSL for traffic between nodes
* Create a network security group (NSG) to close off communication to ports that are not actively used
* Enable authentication for connections to the database as well.
