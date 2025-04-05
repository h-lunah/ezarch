#!/bin/bash
set -e
DEV=$1

if ! [[ "$DEV" =~ ^/dev/* ]]
then
    printf "Invalid device provided.\nIn case you're wondering, run './ezarch.sh' to allow this script to continue.\n"
    exit 1
fi

# Install the GRUB bootloader
# This is the part that allows you to boot into the system.
pacman --noconfirm -Sy grub efibootmgr
if [ -e /sys/firmware/efi/efivars ]
then
    grub-install --target=x86_64-efi --force $DEV
else
    grub-install --target=i386-pc --force $DEV
fi
grub-mkconfig -o /boot/grub/grub.cfg

# Ask for and set up the root password.
# Please pick something secure, or you'll get kids fucking around in your computer.
echo "Please enter your root password: "
read -s ROOTPASS
echo "root:$ROOTPASS" | chpasswd

# Ask and setup the username and password of the regular user.
# This user will have sudo privileges, so please set up a secure password if you don't want kids fucking around in your computer.
read -p "Enter the username of your user: " USERNAME
useradd -m $USERNAME
usermod -aG wheel $USERNAME
echo "Please enter your user password: "
read -s USERPASS
echo "$USERNAME:$USERPASS" | chpasswd

# Enable wheel privileges for sudo
# They don't get configured with the installation of the package.
read -p "Edit /etc/sudoers interactively? (recommended) [Y/n]" USE_VISUDO
USE_VISUDO=${USE_VISUDO:-y}
USE_VISUDO=$(echo "$USE_VISUDO" | tr '[:upper:]' '[:lower:]')
if [ USE_VISUDO = "y" ]; then
  EDITOR=nano visudo
else
  sed -i 's/^#\s*\(%wheel\s\+ALL=(ALL)\s\+NOPASSWD:\s\+ALL\)/\1/' /etc/sudoers
fi

# Delete GRUB after setup
# GRUB packages are not needed after setup, so they will be deleted to save space.
pacman --noconfirm -R grub efibootmgr

# Enable network services
# These services will allow you to connect to the internet.
systemctl enable NetworkManager

# Remove the chroot file
# This also saves space.
rm -rf /ezarch-chroot.sh
exit
