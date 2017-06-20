#!/usr/bin/env bash

# Azure public IPs have some odd keep alive behaviour
# A summary is available here https://docs.mongodb.org/ecosystem/platforms/windows-azure/

echo "Setting TCP keepalive..."
sysctl -w net.ipv4.tcp_keepalive_time=120

echo "Setting TCP keepalive permanently..."
echo "net.ipv4.tcp_keepalive_time = 120" >> /etc/sysctl.conf
echo "" >> /etc/sysctl.conf
