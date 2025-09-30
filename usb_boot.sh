#!/bin/bash
# Radxa Zero - Boot from eMMC, Run from USB
# This keeps the bootloader on eMMC but moves the root filesystem to USB

# PREREQUISITES:
# - Fresh Debian installed on eMMC and booted
# - USB drive connected as /dev/sda
# - Run each section carefully and verify output

echo "=========================================="
echo "Step 1: Create GPT partition table on USB"
echo "=========================================="
echo "WARNING: This will ERASE all data on /dev/sda"
read -p "Press Enter to continue or Ctrl+C to abort..."

sudo gdisk /dev/sda << EOF
o
y
n
1

+512M
ef00
n
2


8300
w
y
EOF

echo ""
echo "Reloading partition table..."
sudo partprobe /dev/sda
sleep 2

echo ""
echo "=========================================="
echo "Step 2: Format the partitions"
echo "=========================================="

sudo apt update
sudo apt install -y e2fsprogs dosfstools rsync

sudo mkfs.vfat -F32 /dev/sda1
sudo mkfs.ext4 /dev/sda2

echo ""
echo "=========================================="
echo "Step 3: Mount USB partitions"
echo "=========================================="

sudo mkdir -p /mnt/usb
sudo mount /dev/sda2 /mnt/usb
sudo mkdir -p /mnt/usb/boot/efi
sudo mount /dev/sda1 /mnt/usb/boot/efi

echo ""
echo "Mounted partitions:"
lsblk /dev/sda

echo ""
echo "=========================================="
echo "Step 4: Copy root filesystem to USB"
echo "=========================================="

sudo rsync -aAXv / /mnt/usb \
  --exclude={"/dev/*","/proc/*","/sys/*","/tmp/*","/run/*","/mnt/*","/media/*","/lost+found","/boot/*"}

echo ""
echo "=========================================="
echo "Step 5: Copy boot files to USB"
echo "=========================================="

sudo mkdir -p /mnt/usb/boot
sudo cp -a /boot/vmlinuz-* /mnt/usb/boot/
sudo cp -a /boot/initrd.img-* /mnt/usb/boot/
sudo cp -a /boot/System.map-* /mnt/usb/boot/
sudo cp -a /boot/config-* /mnt/usb/boot/
sudo cp -r /boot/dtbo /mnt/usb/boot/ 2>/dev/null || true
sudo cp /boot/uEnv.txt /mnt/usb/boot/ 2>/dev/null || true
sudo cp /boot/hw_intfc.conf /mnt/usb/boot/ 2>/dev/null || true

sudo mkdir -p /mnt/usb/usr/lib/linux-image-6.1.68-3-stable/
sudo cp -r /usr/lib/linux-image-6.1.68-3-stable/* /mnt/usb/usr/lib/linux-image-6.1.68-3-stable/ 2>/dev/null || true

echo ""
echo "=========================================="
echo "Step 6: Update fstab on USB"
echo "=========================================="

# Ensure partitions are detected before blkid
sudo partprobe
sudo udevadm settle

# Get UUIDs
USB_EFI_UUID=$(blkid -s UUID -o value /dev/sda1)
USB_ROOT_UUID=$(blkid -s UUID -o value /dev/sda2)

if [ -z "$USB_EFI_UUID" ] || [ -z "$USB_ROOT_UUID" ]; then
    echo "ERROR: Could not get UUIDs for /dev/sda1 or /dev/sda2"
    lsblk -f /dev/sda
    exit 1
fi

echo "USB EFI UUID: $USB_EFI_UUID"
echo "USB Root UUID: $USB_ROOT_UUID"

sudo cp /mnt/usb/etc/fstab /mnt/usb/etc/fstab.backup

cat << FSTAB | sudo tee /mnt/usb/etc/fstab
UUID=$USB_ROOT_UUID / ext4 defaults 0 1
UUID=$USB_EFI_UUID /boot/efi vfat defaults,x-systemd.automount,fmask=0077,dmask=0077 0 2
FSTAB

echo ""
echo "New USB fstab:"
cat /mnt/usb/etc/fstab

echo ""
echo "=========================================="
echo "Step 7: Update eMMC boot config to point to USB"
echo "=========================================="

sudo cp /boot/extlinux/extlinux.conf /boot/extlinux/extlinux.conf.backup
sudo sed -i "s|root=UUID=[^ ]*|root=UUID=$USB_ROOT_UUID|g" /boot/extlinux/extlinux.conf

echo ""
echo "Updated eMMC extlinux.conf:"
grep "root=UUID" /boot/extlinux/extlinux.conf

echo ""
echo "=========================================="
echo "Step 8: Sync and unmount"
echo "=========================================="

sync
sudo umount /mnt/usb/boot/efi
sudo umount /mnt/usb

echo ""
echo "=========================================="
echo "Step 9: Configure WiFi autoconnect and ssh"
echo "=========================================="

# Mount USB root temporarily to chroot inside
sudo mount /dev/sda2 /mnt/usb
sudo mount --bind /dev /mnt/usb/dev
sudo mount --bind /proc /mnt/usb/proc
sudo mount --bind /sys /mnt/usb/sys

sudo chroot /mnt/usb /bin/bash -c "
nmcli dev wifi connect 'CERMOB_POS' password 'cermobpos123'
nmcli connection modify 'CERMOB_POS' connection.autoconnect yes
nmcli connection modify 'CERMOB_POS' wifi-sec.key-mgmt wpa-psk
nmcli connection modify 'CERMOB_POS' 802-11-wireless-security.psk 'cermobpos123'
"

sudo chroot /mnt/usb /bin/bash -c "
apt update
apt install -y openssh-server
systemctl enable ssh
"

# Cleanup mounts
sudo umount /mnt/usb/dev
sudo umount /mnt/usb/proc
sudo umount /mnt/usb/sys
sudo umount /mnt/usb

echo ""
echo "=========================================="
echo "Setup Complete!"
echo "=========================================="
echo ""
echo "Next boot will load kernel from eMMC but rootfs from USB (/dev/sda2)"
read -p "Press Enter to reboot now, or Ctrl+C to cancel..."
sudo reboot
