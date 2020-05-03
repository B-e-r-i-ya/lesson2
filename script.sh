#!/bin/bash
yum install -y mdadm
yes|mdadm --create --verbose /dev/md0 -l 1 -n 3 /dev/sd{b,c,d}
mkdir /etc/mdadm
echo "DEVICE partitions" > /etc/mdadm/mdadm.conf
yes|mdadm --detail --scan --verbose | awk '/ARRAY/ {print}' >> /etc/mdadm/mdadm.conf

