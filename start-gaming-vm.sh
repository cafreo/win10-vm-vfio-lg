#! /bin/sh
sudo systemctl restart libvirtd
sudo -S virsh start win10G
looking-glass-client
