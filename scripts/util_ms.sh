#!/usr/bin/env bash

adjustTCPKeepalive ()
{
# Azure public IPs have some odd keep alive behaviour

echo "Setting TCP keepalive..."
sysctl -w net.ipv4.tcp_keepalive_time=120

echo "Setting TCP keepalive permanently..."
echo "net.ipv4.tcp_keepalive_time = 120
" >> /etc/sysctl.conf
}

addSwapFile ()
{
# It also sets the swap file to 32GB on /mnt which is the temporary disk on /dev/sdb
# This expects the waagent to be running and /etc/waagent.conf to exist

WAAGENT_CONF="/etc/waagent.conf"

sed -i 's/ResourceDisk.Format=n/ResourceDisk.Format=y/g' $WAAGENT_CONF
sed -i 's/ResourceDisk.EnableSwap=n/ResourceDisk.EnableSwap=y/g' $WAAGENT_CONF
sed -i 's/ResourceDisk.SwapSizeMB=0/ResourceDisk.SwapSizeMB=32768/g' $WAAGENT_CONF

systemctl restart walinuxagent.service
}

formatDataDisk2 (){
# This script formats and mounts the drive on lun0 as /datadisk

DISK1="/dev/disk/azure/scsi1/lun0"
PARTITION1="/dev/disk/azure/scsi1/lun0-part1"
MOUNTPOINT1="/datadisk/data"
DISK2="/dev/disk/azure/scsi1/lun1"
PARTITION2="/dev/disk/azure/scsi1/lun1-part1"
MOUNTPOINT2="/datadisk/index"

echo "Partitioning the disk."
echo "g
n
p
1


t
83
w"| fdisk ${DISK1}

echo "Partitioning the disk."
echo "g
n
p
1


t
83
w"| fdisk ${DISK2}

echo "Waiting for the symbolic link to be created..."
udevadm settle --exit-if-exists=$PARTITION1
udevadm settle --exit-if-exists=$PARTITION2

echo "Creating the filesystem."
mkfs -j -t ext4 ${PARTITION1}
mkfs -j -t ext4 ${PARTITION2}

echo "Updating fstab"
LINE1="${PARTITION1}\t${MOUNTPOINT1}\text4\tnoatime,nodiratime,nodev,noexec,nosuid\t1\t2"
LINE2="${PARTITION2}\t${MOUNTPOINT2}\text4\tnoatime,nodiratime,nodev,noexec,nosuid\t1\t2"
echo -e ${LINE1} >> /etc/fstab
echo -e ${LINE2} >> /etc/fstab

echo "Mounting the disk"
mkdir -p $MOUNTPOINT1
mkdir -p $MOUNTPOINT2
mount -a

echo "Changing permissions"
chown couchbase $MOUNTPOINT1
chown couchbase $MOUNTPOINT2
chgrp couchbase $MOUNTPOINT1
chgrp couchbase $MOUNTPOINT2   
}

formatDataDisk ()
{
# This script formats and mounts the drive on lun0 as /datadisk

DISK="/dev/disk/azure/scsi1/lun0"
PARTITION="/dev/disk/azure/scsi1/lun0-part1"
MOUNTPOINT="/datadisk"

echo "Partitioning the disk."
echo "g
n
p
1


t
83
w"| fdisk ${DISK}

echo "Waiting for the symbolic link to be created..."
udevadm settle --exit-if-exists=$PARTITION

echo "Creating the filesystem."
mkfs -j -t ext4 ${PARTITION}

echo "Updating fstab"
LINE="${PARTITION}\t${MOUNTPOINT}\text4\tnoatime,nodiratime,nodev,noexec,nosuid\t1\t2"
echo -e ${LINE} >> /etc/fstab

echo "Mounting the disk"
mkdir -p $MOUNTPOINT
mount -a

echo "Changing permissions"
chown couchbase $MOUNTPOINT
chgrp couchbase $MOUNTPOINT
}

turnOffTHPsystemd ()
{
#Turn off thp using systemd
cat << EOM > /etc/systemd/system/disable-thp.service
[Unit]
Description=Disable Transparent Huge Pages (THP)

[Service]
Type=simple
ExecStart=/bin/sh -c "echo 'never' > /sys/kernel/mm/transparent_hugepage/enabled && echo 'never' > /sys/kernel/mm/transparent_hugepage/defrag"

[Install]
WantedBy=multi-user.target
EOM
systemctl daemon-reload
systemctl start disable-thp
systemctl enable disable-thp

}

turnOffTransparentHugepages ()
{
echo "#!/bin/bash
### BEGIN INIT INFO
# Provides:          disable-thp
# Required-Start:    $local_fs
# Required-Stop:
# X-Start-Before:    couchbase-server
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: Disable THP
# Description:       disables Transparent Huge Pages (THP) on boot
### END INIT INFO

echo 'never' > /sys/kernel/mm/transparent_hugepage/enabled
echo 'never' > /sys/kernel/mm/transparent_hugepage/defrag
" > /etc/init.d/disable-thp
chmod 755 /etc/init.d/disable-thp
service disable-thp start
update-rc.d disable-thp defaults
}

setSwappinessToZero ()
{
sysctl vm.swappiness=0
echo "
# Required for Couchbase
vm.swappiness = 0
" >> /etc/sysctl.conf
}

addCBGroup ()
{    
    $username = $1
    $password = $2
    path = ${3-'/opt/couchbase/bin/'}
    cli=${path}couchbase-cli group-manage
    ls $path
    $cli --username $username --password $password --create --group-name
    #runs in the directory where couchbase is installed
}
