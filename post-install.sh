#!/bin/bash

echo "Configurador de Arch de Gaizka"

#Establecer zona horaria
ln -sf /usr/share/zoneinfo/Europe/Madrid /etc/localtime
hwclock --systohc

# Set locale to en_US.UTF-8 UTF-8
sed -i '/es_ES.UTF-8/s/^#//g' /etc/locale.gen
locale-gen
echo "LANG=es_ES.UTF-8" >> /etc/locale.conf
echo "KEYMAP=ES" >> /etc/vconsole.conf

# Set hostname
echo "ArchPc" >> /etc/hostname
echo "127.0.0.1 localhost" >> /etc/hosts
echo "::1 localhost" >> /etc/hosts
echo "127.0.1.1 ArchPc.localdomain  ArchPc" >> /etc/hosts

# Set root password
echo "Escribe el password para el usuario root"
passwd

# Install bootloader
echo "Discos detectados:"
lsblk|grep disk|grep -v

echo ""
read -p "Escribe el nombre del disco donde se instalará GRUB: " TARGET
mkdir /boot/efi
mount /dev/${TARGET}1 /boot/efi
grub-install --target=x86_64-efi --bootloader-id=GRUB --efi-directory=/boot/efi --removable
os-prober
grub-mkconfig -o /boot/grub/grub.cfg

# Create new user
read -p "Escribe el nombre del nuevo usuario: " USER
useradd -m -g users -G wheel -s /bin/bash $USER
sed --in-place 's/^#\s*\(%wheel\s\+ALL=(ALL)\s\+NOPASSWD:\s\+ALL\)/\1/' /etc/sudoers
echo "Escribe el password para el usuario $USER"
passwd $USER

#Actualizar repositorios
sudo reflector -c "ES" -f 12 -l 10 -n 12 --save /etc/pacman.d/mirrorlist

echo "Selección del gestor de inicio de sesión:"
echo "1.- Sddm (Kde)"
echo "2.- Gdm (Gnome)"
echo "3.- Mdm (Cinnamon)"
echo "4.- Lightdm (Mate)"
echo "5.- Lightdm (Deepin)"
echo "6.- LXdm (LXDE)"
while :
do
    read -p "Qué escritorio quieres instalar? " pGestor
    case $pGestor in
        1)
            echo "Instalando Sddm"
            pacman -S sddm sddm-kcm
            systemctl enable sddm.service
            break
            ;;
        2)
            echo "Instalando Gdm"
            pacman -S gdm
            systemctl enable gdm.service
            break
            ;;
        3)
            echo "Instalando Mdm"
            pacman -S mdm
            systemctl enable mdm.service
            break
            ;;
        4)
            echo "Instalando Lightdm"
            pacman -S lightdm lightdm-gtk-greeter
            systemctl enable lightdm.service
            break
            ;;
        5)
            echo "Instalando Lightdm"
            pacman -S lightdm lightdm-gtk-greeter
            echo "greeter-session=lightdm-deepin-greeter" >> /etc/lightdm/lightdm.conf
            systemctl enable lightdm.service
            break
            ;;
        6)
            echo "Instalando LXdm"
            pacman -S lxdm
            systemctl enable lxdm.service
            break
            ;;
        *)
            echo "Opción no válida, inténtalo de nuevo."
            ;;
    esac
done

# Enable services
systemctl enable NetworkManager.service

#Modificar swappiness
echo "vm.swappiness=10" >> /etc/sysctl.d/99-swappiness.conf

#Activar multilib
sed -i "/\[multilib\]/,/Include/"'s/^#//' /etc/pacman.conf

echo "Configuration completada. Ya puedes salir de chroot, teclea exit"
