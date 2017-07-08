#!/usr/bin/env bash

# This script formats and mounts the drive on lun0 as /mnt/datadisk

DISK="/dev/disk/azure/scsi1/lun0"
DEVICE="/dev/disk/azure/scsi1/lun0-part1"
MOUNTPOINT="/mnt/datadisk"

echo "Partitioning the disk."
echo "n
p
1


t
83
w"| fdisk ${DISK}

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
