#! /bin/sh
#kitty -e sudo systemctl restart libvirtd
#wait
kitty -e sudo -S virsh start win10
looking-glass-client
