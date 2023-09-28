#! /bin/sh
#kitty -e sudo systemctl restart libvirtd
#wait
#sudo chmod 666 /dev/vfio/vfio &&
kitty -e --title "Looking Glass win10VM" sudo sh -c 'virsh start win10; bash /home/cafreo/Scripts/VM/xboxc-usb.sh attach';
looking-glass-client
