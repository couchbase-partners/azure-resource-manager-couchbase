#!/usr/bin/env bash

# This script formats and mounts the drive on lun1 as /mnt/datadisk

DEVICE="/dev/disks/azure/datadisks/lun"
MOUNTPOINT="/mnt/datadisk"

echo "Partitioning the disk."
echo "n
p
1


t
83
w"| fdisk ${DEVICE}

echo "Creating the filesystem."
mkfs -j -t ext4 ${DEVICE}

echo "Updating fstab"
LINE="${DEVICE}\t${MOUNTPOINT}\text4\tnoatime,nodiratime,nodev,noexec,nosuid\t1\t2"
echo -e ${LINE} >> /etc/fstab

echo "Mounting the disk"
mkdir -p $MOUNTPOINT
mount -a

echo "Changing permissions"
chown couchbase $MOUNTPOINT
chgrp couchbase $MOUNTPOINT
