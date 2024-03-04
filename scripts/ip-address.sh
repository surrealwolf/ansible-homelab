#!/bin/bash

# Check if user is root
if [ $(id -u) -ne 0 ]; then
   echo "This script must be run as root"
   exit 1
fi

reset () {
        test -f /etc/netplan/01-netcfg.yaml && rm -f /etc/netplan/01-netcfg.yaml
        test -f /opt/scripts/.bak/00-installer-config.yaml || cp /etc/netplan/00-installer-config.yaml /opt/scripts/.bak/00-installer-config.yaml
        cp -f /opt/scripts/.bak/00-installer-config.yaml /etc/netplan/00-installer-config.yaml
}

update () {
        rm -f /etc/netplan/00-installer-config.yaml
        cp -f /opt/scripts/.template/01-netcfg.yaml /etc/netplan/01-netcfg.yaml
        netplan set ethernets.ens33.addresses=[$1]
        netplan try && netplan apply
        netplan get
}

# reset ip address
reset

# get desired ip address
clear
netplan get
echo
echo What IP Address should I use? 192.168.10.x/24
echo
read ip
echo
echo "New IP Address: $ip"
echo
while read -n1 -r -p "Is this correct? [y]es|[n]o - "
do
        if [[ $REPLY == y ]];
        then
                update $ip
                break
        else
                clear
                netplan get
                echo
                echo What IP Address should I use? 192.168.10.x/24
                echo
                read ip
                echo
                echo "New IP Address: $ip"
                echo
        fi
done