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
echo "Escribe el password para el usuario root:"
passwd

# Install bootloader
echo ""
echo "Discos detectados:"
lsblk
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
echo "Escribe el password para el usuario $USER:"
passwd $USER

#Actualizar repositorios
reflector -c "ES" -f 12 -l 10 -n 12 --save /etc/pacman.d/mirrorlist

echo "Selección del entorno de escritorio:"
echo "1.- Kde"
echo "2.- Gnome"
echo "3.- Cinnamon"
echo "4.- Mate"
echo "5.- Deepin"
echo "6.- LXDE"
while :
do
    read -p "Qué escritorio quieres instalar? " pEscritorio
    case $pEscritorio in
        1)
            echo "Instalando Kde"
            pacman -S --noconfirm plasma-desktop user-manager kscreen konsole dolphin kate breeze-gtk kde-gtk-config libappindicator-gtk3 plasma-nm plasma-pa ark okular kinfocenter kwalletmanager transmission-qt gwenview kipi-plugins spectacle kcolorchooser vlc konversation
            break
            ;;
        2)
            echo "Instalando Gnome"
            pacman -S --noconfirm gnome
            break
            ;;
        3)
            echo "Instalando Cinnamon"
            pacman -S --noconfirm cinnamon
            break
            ;;
        4)
            echo "Instalando Mate"
            pacman -S --noconfirm mate
            break
            ;;
        5)
            echo "Instalando Deepin"
            pacman -S --noconfirm deepin
            break
            ;;
        6)
            echo "Instalando LXDE"
            pacman -S --noconfirm lxdm-gtk3
            break
            ;;
        *)
            echo "Opción no válida, inténtalo de nuevo."
            ;;
    esac
done

echo "Selección del gestor de inicio de sesión:"
echo "1.- Sddm (Kde)"
echo "2.- Gdm (Gnome)"
echo "3.- Lightdm (Cinnamon/Mate)"
echo "4.- Lightdm (Deepin)"
echo "5.- LXdm (LXDE)"
while :
do
    read -p "Qué gestor de inicio de sesión quieres instalar? " pGestor
    case $pGestor in
        1)
            echo "Instalando Sddm"
            pacman -S --noconfirm sddm sddm-kcm
            systemctl enable sddm.service
            break
            ;;
        2)
            echo "Instalando Gdm"
            pacman -S --noconfirm gdm
            systemctl enable gdm.service
            break
            ;;
        3)
            echo "Instalando Lightdm"
            pacman -S --noconfirm lightdm lightdm-gtk-greeter
            systemctl enable lightdm.service
            break
            ;;
        4)
            echo "Instalando Lightdm"
            pacman -S --noconfirm lightdm lightdm-gtk-greeter
            echo "greeter-session=lightdm-deepin-greeter" >> /etc/lightdm/lightdm.conf
            systemctl enable lightdm.service
            break
            ;;
        5)
            echo "Instalando LXdm"
            pacman -S --noconfirm lxdm
            systemctl enable lxdm.service
            break
            ;;
        *)
            echo "Opción no válida, inténtalo de nuevo."
            ;;
    esac
done

echo "Selección del navegador:"
echo "1.- Firefox"
echo "2.- Chromium"
while :
do
    read -p "Qué navegador quieres instalar? " pNavegador
    case $pNavegador in
        1)
            echo "Instalando Firefox"
            pacman -S --noconfirm firefox
            break
            ;;
        2)
            echo "Instalando Chromium"
            pacman -S --noconfirm chromium
            break
            ;;
        *)
            echo "Opción no válida, inténtalo de nuevo."
            ;;
    esac
done

#Activar multilib
sed -i "/\[multilib\]/,/Include/"'s/^#//' /etc/pacman.conf
pacman -Syy

read -p "Quieres instalar bluetooth? [y/N]" pBluetooth
if ! [ $pBluetooth = 'y' ] && ! [ $pBluetooth = 'Y' ]
then
    echo "No se instalará Bluetooth"
else
    echo "Instalando Bluetooth"
    pacman -S --noconfirm bluez bluez-utils 
fi

read -p "Quieres instalar Discord? [y/N]" pDiscord
if ! [ $pDiscord = 'y' ] && ! [ $pDiscord = 'Y' ]
then
    echo "No se instalará Discord"
else
    echo "Instalando Discord"
    pacman -S --noconfirm discord
fi

read -p "Quieres instalar Wine? [y/N]" pWine
if ! [ $pWine = 'y' ] && ! [ $pWine = 'Y' ]
then
    echo "No se instalará Wine"
else
    echo "Instalando Wine, Dxvk y sus dependencias"
    pacman -S --noconfirm wine-staging nvidia-dkms nvidia-utils lib32-nvidia-utils nvidia-settings vulkan-icd-loader lib32-vulkan-icd-loader giflib lib32-giflib libpng lib32-libpng libldap lib32-libldap gnutls lib32-gnutls mpg123 lib32-mpg123 openal lib32-openal v4l-utils lib32-v4l-utils libpulse lib32-libpulse libgpg-error lib32-libgpg-error alsa-plugins lib32-alsa-plugins alsa-lib lib32-alsa-lib libjpeg-turbo lib32-libjpeg-turbo sqlite lib32-sqlite libxcomposite lib32-libxcomposite libxinerama lib32-libgcrypt libgcrypt lib32-libxinerama ncurses lib32-ncurses opencl-icd-loader lib32-opencl-icd-loader libxslt lib32-libxslt libva lib32-libva gtk3 lib32-gtk3 gst-plugins-base-libs lib32-gst-plugins-base-libs vulkan-icd-loader lib32-vulkan-icd-loader
fi

read -p "Quieres instalar Lutris? [y/N]" pLutris
if ! [ $pLutris = 'y' ] && ! [ $pLutris = 'Y' ]
then
    echo "No se instalará Lutris"
else
    echo "Instalando Lutris"
    pacman -S --noconfirm lutris
fi

# Enable services
systemctl enable NetworkManager.service

#Modificar swappiness
echo "vm.swappiness=10" >> /etc/sysctl.d/99-swappiness.conf

echo "Configuration completada. Ya puedes salir de chroot, teclea exit"
