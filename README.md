# win10-vm-vfio-lg
 XML setup for my Win10 virtual machine with vfio gpu passthrough, cpu pinning and other optimizations to run in looking glass

### Previous Video to Watch

[Link](https://www.youtube.com/watch?v=KVDUs019IB8)

### Requirements

Hardware:

- 2 GPUs (integrated or dedicated)
- Display Dummy Plug (HDMI, DP, etc.)
- free power slot at power supply
- at least 2 pcie slots, 3+ preferred for bigger graphics cards, host gpu in slot before passthrough gpu
- SSD recommended

Software (Linux Host):

- OS: Arch Linux based, Gentoo, VFIO kernel available, customized kernel* (not necessary for iGPU)
- Virt-Manager, QEMU, LG (Client)
- Arch: downgrade package (optional)

*to split your IOMMU groups in a custom kernel you have to activate the ACS override patch in the kernel config and then compile it (this will make your system less secure [Link](https://www.reddit.com/r/VFIO/comments/bvif8d/official_reason_why_acs_override_patch_is_not_in/) )

[Link](https://old.reddit.com/r/VFIO/comments/ifza0k/split_iommu_groups/)

Software (Windows Client):

- LG (Host)
- VirtIO drivers/guest tools, SPICE Guest Tools
- Riva Tuner Statistics Server (optional, see GPU Flushing)
- Scale and Layout: 100%
- Mouse Settings: Sensitivity: Default (10), Advanced Pointer Precision: Disabled

### Virt-Manager Settings (Essentials)

- CPUs: Configuration: Skylake for me (What fits your CPU model)
- Topology: keep the same as CPU pinning settings
- add your USB Mouse
- add your USB Keyboard
- add Channel: Name: com.redhat.spice.0 ; Device Type: Spice agent (spicevmc)

### Virt-Manager Settings (Optional)

- adding a full disk/partition to the system:
    - `lsblk` -> NAME
    - `ls -l /dev/disk/by-id/` DISK_ID that points to NAME
    - copy /dev/disk/by-id/$DISK_ID to "Select or create custom storage"
    - Bus type: VirtIO

### CPU Pinning

```
<domain type='kvm' ...>
 ...
 <vcpu placement='static'>14</vcpu>
 <iothreads>1</iothreads>
 <cputune>
    <vcpupin vcpu='0' cpuset='1'/>
    <vcpupin vcpu='1' cpuset='2'/>
    <vcpupin vcpu='2' cpuset='3'/>
    <vcpupin vcpu='3' cpuset='4'/>
    <vcpupin vcpu='4' cpuset='5'/>
    <vcpupin vcpu='5' cpuset='6'/>
    <emulatorpin cpuset='0,8'/>
    <iothreadpin iothread='1' cpuset='0,8'/>
 </cputune>
 ...
</domain>
```

[Link](https://leduccc.medium.com/improving-the-performance-of-a-windows-10-guest-on-qemu-a5b3f54d9cf5)

### SAMBA Shares

**Linux Host Setup:**

/etc/samba/smb.conf

```
[global]
  usershare path = /var/lib/samba/usershares
  usershare max shares = 100
  usershare allow guests = yes
  usershare owner only = yes
  hosts allow = 192.168.0.0/16
  hosts deny = 0.0.0.0/0
  map to guest = Bad User
  server role = standalone server

[Share Folder]
  comment = share items to VM
  path = /home/$YOUR_USER/Share
  read only = no
  guest ok = yes
  force user = $YOUR_USER
  force group = $YOUR_USER
```

**Windows Client Setup:**

Windows Features:

Enable SMB 1.0/CIFS File Sharing Support

- CIFS Automatic Removal

- CIFS Client

Open Terminal -> ipconfig -> Default Gateway: copy IP address

Windows Explorer:

Go to "This PC" -> Right Click -> Add network location or Map Network Drive -> \\$COPIED_IP_ADDRESS\Share -> Next define name or Drive Letter -> Done

[Link](https://www.youtube.com/watch?v=oRHSrnQueak)

&nbsp;

### FPS not stable / micro stuttering

Increase the ingame FPS to slightly (10%-15% of your preferred FPS) above your current FPS. Example: If you play in 60FPS, increase it to at least 70-80FPS

*Explanation: Since LG is losing some FPS by sending them from the LG host to the LG client and it is kept at the FPS of the game you are "streaming" small frame drops of 4-5 FPS are very noticeable. Increasing your FPS will make these rare frame drops way less noticeable, since LG will still stay above your preferred threshhold.*

[Link](https://forum.level1techs.com/t/ups-understanding-and-infos/159563)

### Auto connect USB-device (Gamepad) to VM (via udev)

`lsusb` -> find the USB-device you want to redirect to the VM -> ID XXXX:YYYY

create $NAME.rules file in `/etc/udev/rules.d` :

```
ACTION=="bind", \
  SUBSYSTEM=="usb", \
  ENV{ID_VENDOR_ID}=="XXXX", \
  ENV{ID_MODEL_ID}=="YYYY", \
  RUN+="/absolute/path/to/script.sh attach"
ACTION=="remove", \
  SUBSYSTEM=="usb", \
  ENV{ID_VENDOR_ID}=="XXXX", \
  ENV{ID_MODEL_ID}=="YYYY", \
  RUN+="/absolute/path/to/script.sh detach"
```

create new script at your preferred location:

```
#!/bin/sh
ACTION=$1
virsh "${ACTION}-device" $VM_DOMAIN --file /path/to/properties.xml --current
```

create new xml file:

```
<hostdev mode='subsystem' type='usb' managed='yes'>
   <source>
     <vendor id='0xXXXX'/>
     <product id='0xYYYY'/>
   </source>
</hostdev>
```

debug errors:

`sudo udevadm control --log-priority=debug` -> `journalctl -u systemd-udev`

reload udev:

`sudo udevadm control --reload-rules && sudo udevadm trigger`

[Link 1](https://nickpegg.com/2021/01/kvm-usb-auto-passthrough/) [Link 2](https://unix.stackexchange.com/questions/714993/redirect-usb-device-in-kvm-while-guest-is-running "https://overflow.adminforge.de/exchange/unix/questions/714993/redirect-usb-device-in-kvm-while-guest-is-running")

&nbsp;

### GPU Flushing (optional, mostly for iGPU Host)

Decreases framerate but increases Frame stability. Great for iGPU host devices

Tool: Riva Tuner Statistics Server ([Download](https://www.guru3d.com/files-details/rtss-rivatuner-statistics-server-download.html))

Open Config in `C:\Program Files (x86)\RivaTuner Statistics Server\Profiles\` and add `SyncFlush=2`

Set Scanline sync for Global or Game.exe to 1. This will take effect right away. You do not need to restart the game.

It is recommended to turn Vertical Sync off in any game, since this can cause weird display issues.

[Link](https://forum.level1techs.com/t/improving-looking-glass-capture-performance/141719)

### Hyperv (optional, not sure what this does)

**KVM xml file setup**

```xml
<domain type='kvm' ...>
    ...
    <features>
        <acpi/>
        <apic/>
        <pae/>
        <hyperv>
            ...
            <relaxed state='on'/>
            <vapic state='on'/>
            <spinlocks state='on' retries='8191'/>
            <vpindex state='on'/>
            <synic state='on'/>
            <stimer state='on'/>
            <reset state='on'/>
            ...
        </hyperv>
    </features>
    <clock ...>
        ...
        <timer name='hpet' present='yes'/>
        <timer name='hypervclock' present='yes'/>
        ...
    </clock>
    ...
</domain>
```

**Windows Client Setup**

Install Hyperv on Windows:

Windows Features:

Hyper-V

- Hyper-V Management Tools

- Hyper-V Platform

&nbsp;

### Encountered Errors

&nbsp;

**failed to open /dev/vfio/vfio: Permission denied**

add `SUBSYSTEM=="vfio", OWNER="root", GROUP="kvm"` to /etc/udev/udev.conf

run  `sudo udevadm control --reload-rules && sudo udevadm trigger`

**clipboard not working**

open Services in Windows

look for SPICE VDAgent -> Properties -> General: Startup type: "Automatic" -> Recovery: set all failure types to "Restart the Service" -> "OK"

*this should work at least temporarily; if it doesn't work permanently, see next step:*

look for Spice Agent -> Properties -> General: Startup type: "Disabled" -> "OK"

&nbsp;

### Smaller Inconveniences

&nbsp;

**System freezing completely**

probably the host didn't have enough ram and froze completely. after ~10 sec. the VM is getting killed and the host system should be usable again. all progress in the VM will be lost though.

**Mouse jumping**

could be problem of DE/window manager. Hyprland 0.29.1 has this problem. Downgrade to older version or wait for patch

&nbsp;

### More in depth / personal preference things

**2.1— CPU mode, topology**

The CPU mode you pick will be one of the biggest factor in CPU related performance. If you disable all CPU emulation and pass the CPU as-is to the VM using the “host-passthrough” mode then your performance will be as close to bare metal as can be for CPU bound tasks.

*Explanation: This is not true for my system. Setting my CPU to "host-passthrough" reduced my performance significally, to the point, where I had lags in games that are very old and not even CPU intensive. Setting the topology to the preset that fits my CPU the best or is the most similar, gave me native performance.*

**3.1— CPU Isolation**

If you are experiencing micro stutters or missed frame on higher resolutions (4k or 4k ultrawide) it can be beneficial to isolate the cores responsible for the virtualization I/O and emulator processes from the host and guest processes.

*Explanation: I don't have a 4K monitor, so I can't test it.*

Source: [Link](https://leduccc.medium.com/improving-the-performance-of-a-windows-10-guest-on-qemu-a5b3f54d9cf5)

&nbsp;

**Huge memory pages**

*Explanation: I had no problems with RAM performance, which is why I skipped this.*

Source: [Link](https://wiki.archlinux.org/title/PCI_passthrough_via_OVMF#Huge_memory_pages)

&nbsp;

**Constantly prompting for microphone access**

Windows Client Setup:

Settings -> Privacy -> Microphone

Either: Turn off "Allow access to microphone"

Or: Pick the exact Microsoft Store or Desktop Apps that should not be allowed to access your microphone.

&nbsp;

## Other Recommendations

Symlinks: for example for the minecraft folder not being on your main VM drive, but rather on an external drive

[Link](https://www.howtogeek.com/16226/complete-guide-to-symbolic-links-symlinks-on-windows-or-linux/)

Arch Wiki Guide

[Link](https://wiki.archlinux.org/title/PCI_passthrough_via_OVMF)
