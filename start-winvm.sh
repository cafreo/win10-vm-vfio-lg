#! /bin/sh
#kitty -e sudo systemctl restart libvirtd
#wait
#sudo chmod 666 /dev/vfio/vfio &&
kitty -e --title "Looking Glass win10VM" sudo -S virsh start win10;
looking-glass-client
