#!/bin/bash
# This script resizes a partition and extends an LVM volume

# Check if user is root
if [ $(id -u) -ne 0 ]; then
   echo "This script must be run as root"
   exit 1
fi

# Check if arguments are provided
if [ $# -ne 1 ]; then
   echo "Usage: $0 <device>"
   exit 1
fi

# Fix the device

# Get device name, partition number and size
DEVICE=$1
PARTITION=3

# Fix the device if needed and get size
SIZE=$(parted -l | grep ${DEVICE} | awk '{ print $3 }' | tr -d "GB")

# Get current disk size
CURRENT_SIZE=$(lsblk -b ${DEVICE} | awk '{if ($7 == "/") {print $4}}')
CURRENT_SIZE_GB=$(echo "scale=0; ${CURRENT_SIZE}/1024/1024/1024" | bc)

# Get root LV path
ROOT_LV_PATH=$(lvdisplay | grep "LV Path" | awk '{print $3}')

echo "The current size of $DEVICE is $CURRENT_SIZE_GB GB"
echo "The new size of $DEVICE will be $SIZE GB"

# Confirm resize with user input
read -p "Are you sure you want to resize the partition? (y/n) " CONFIRM_RESIZE

if [ "${CONFIRM_RESIZE}" != "y" ]; then
   echo "Partition resize cancelled by user"
   exit 1
fi

# Resize partition using parted command
PARTED_CMD="parted ${DEVICE} resizepart ${PARTITION} ${SIZE}GB"
echo "Running command: ${PARTED_CMD}"
$PARTED_CMD

# Reload partition table
PARTPROBE_CMD="partprobe ${DEVICE}"
echo "Running command: ${PARTPROBE_CMD}"
$PARTPROBE_CMD

# Resize physical volume
PVRESIZE_CMD="pvresize ${DEVICE}${PARTITION}"
echo "Running command: ${PVRESIZE_CMD}"
$PVRESIZE_CMD

# Extend LVM volume using free extents
LVEXTEND_CMD="lvextend -l +$(vgdisplay | grep Free | awk '{print $5}') ${ROOT_LV_PATH}"
echo "Running command: ${LVEXTEND_CMD}"
$LVEXTEND_CMD

# Resize filesystem
RESIZE2FS_CMD="resize2fs ${ROOT_LV_PATH}"
echo "Running command: ${RESIZE2FS_CMD}"
$RESIZE2FS_CMD

# New size
NEW_SIZE=$(df -h | grep ubuntu | awk '{print $2}')
echo "New size of ${DEVICE} is ${NEW_SIZE}"

echo "Partition resized, physical volume resized and LVM volume extended successfully"
