#!/bin/bash

# Check if user is root
if [ $(id -u) -ne 0 ]; then
   echo "This script must be run as root"
   exit 1
fi

reset () {
        test -f /home/admin/scripts/.bak/hosts || cp /etc/hosts /home/admin/scripts/.bak/hosts
        cp -f /home/admin/scripts/.bak/hosts /etc/hosts
}

update () {
        hostnamectl set-hostname $1
        sed -i 's/localhost/'$1'/g' /etc/hosts
}

# reset hostname
reset

# get desired hostname
clear
hostnamectl
echo
echo What hostname should I use?
echo
read name
echo
echo "New Hostname: $name"
echo
while read -n1 -r -p "Is this correct? [y]es|[n]o - "
do
        if [[ $REPLY == y ]];
        then
                update $name
                break
        else
                clear
                hostnamectl
                echo
                echo What hostname should I use?
                echo
                read name
                echo
                echo "New Hostname: $name"
                echo
        fi
done