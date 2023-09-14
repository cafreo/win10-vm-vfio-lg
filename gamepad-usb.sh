#!/bin/sh
ACTION=$1
virsh "${ACTION}-device" win10 --file /home/cafreo/Scripts/VM/xboxc-usb.xml --current
