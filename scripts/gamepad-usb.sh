#!/bin/bash
ACTION=$1
virsh "${ACTION}-device" win10 --file /home/cafreo/.config/vm/scripts/xboxc-usb.xml --current
