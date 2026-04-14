#!/bin/bash
set -e

echo "=== Fix Permissions for Keepalived Scripts ==="
chown root:root /check_backends.sh
chmod 700 /check_backends.sh

echo "=== Enable IP Forward ==="
sysctl -w net.ipv4.ip_forward=1

echo "=== Fix LVS routing ==="
sysctl -w net.ipv4.conf.all.route_localnet=1
sysctl -w net.ipv4.vs.conntrack=1

echo "=== Wait for network ==="
sleep 2

echo "=== Setup IPVS ==="
ipvsadm -C || true

ipvsadm -A -t 172.20.0.100:80 -s rr
ipvsadm -a -t 172.20.0.100:80 -r 172.20.0.10:80 -m
ipvsadm -a -t 172.20.0.100:80 -r 172.20.0.11:80 -m

echo "=== Setup SNAT ==="
iptables -t nat -C POSTROUTING -j MASQUERADE 2>/dev/null || \
iptables -t nat -A POSTROUTING -j MASQUERADE

echo "=== IPVS TABLE ==="
ipvsadm -L -n

echo "=== Start Keepalived ==="

exec keepalived -n -l -f /etc/keepalived/keepalived.conf