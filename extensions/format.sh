#!/usr/bin/env bash

# This script formats and mounts the drive on sdc as /datadisks/disk1
# sda - OS Disk
# sdb - Ephemeral
# sdc - Attached Disk

echo "Partitioning the disk."
DISK="/dev/sdc"
echo "n
p
1


t
83
w"| fdisk ${DISK}

echo "Creating the filesystem."
mkfs -j -t ext4 /dev/sdc1

echo "Updating fstab"
MOUNTPOINT="/datadisks/disk1"
read UUID FS_TYPE < <(blkid -u filesystem ${PARTITION}|awk -F "[= ]" '{print $3" "$5}'|tr -d "\"")
LINE="UUID=\"${UUID}\"\t${MOUNTPOINT}\text4\tnoatime,nodiratime,nodev,noexec,nosuid\t1 2"
echo -e "${LINE}" >> /etc/fstab

echo "Mounting the disk"
mkdir -p ${MOUNTPOINT}
mount ${MOUNTPOINT}
