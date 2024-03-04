#!/bin/bash

# Check if user is root
if [ $(id -u) -ne 0 ]; then
   echo "This script must be run as root"
   exit 1
fi

# admin user
useradd -m -p $(openssl passwd -1 ash2022) admin
su admin -c 'chsh -s /bin/bash'