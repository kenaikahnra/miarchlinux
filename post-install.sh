#!/bin/bash

clear
echo "Configurador de Arch de Gaizka"
echo ""

#Establecer zona horaria
echo "Configurando zona horaria..."
ln -sf /usr/share/zoneinfo/Europe/Madrid /etc/localtime
hwclock --systohc
echo ""

# Set locale to en_US.UTF-8 UTF-8
echo "Estableciendo configuración local..."
sed -i '/es_ES.UTF-8/s/^#//g' /etc/locale.gen
locale-gen
echo "LANG=es_ES.UTF-8" >> /etc/locale.conf
echo "KEYMAP=es" >> /etc/vconsole.conf
echo ""

# Set hostname
read -p "Escribe el nombre que utilizaras para tu PC: " pPC
echo "$pPC" >> /etc/hostname
echo "127.0.0.1 localhost" >> /etc/hosts
echo "::1 localhost" >> /etc/hosts
echo "127.0.1.1 ${pPC}.localdomain  $pPC" >> /etc/hosts
echo ""

# Set root password
echo "Escribe el password para el usuario root:"
passwd
while [[ $? -ne 0 ]]; do
    passwd
done
echo ""

# Install bootloader
echo "Instalando GRUB en /dev/${TARGET}p1"
mkdir /boot/efi
mount /dev/${TARGET}p1 /boot/efi
grub-install --target=x86_64-efi --bootloader-id=GRUB --efi-directory=/boot/efi --removable
os-prober
grub-mkconfig -o /boot/grub/grub.cfg
echo ""

# Crear usuarios
echo "Creación de usuarios con permisos de administrador:"
for (( ; ; ))
do
    echo ""
    read -p "Escribe el nombre del nuevo usuario: " pUser
    useradd -m -g users -G wheel -s /bin/bash $pUser
    echo ""
    echo "Escribe el password para el usuario $pUser:"
    passwd $pUser
    while [[ $? -ne 0 ]]; do
      passwd $pUser
    done
    echo ""
    sed --in-place 's/^#\s*\(%wheel\s\+ALL=(ALL)\s\+NOPASSWD:\s\+ALL\)/\1/' /etc/sudoers
    read -p "El usuario se ha creado correctamente, quieres crear más usuarios? [s/n] " pUsuario
    if ! [ $pUsuario = 's' ] && ! [ $pUsuario = 'S' ]
    then
        echo ""
        break
    fi
done

#Actualizar repositorios
echo "Actualizando repositorios..."
reflector -c "ES" -f 12 -l 10 -n 12 --save /etc/pacman.d/mirrorlist
echo ""

#Activar multilib
echo "Activando el repositorio [multilib]..."
sed -i "/\[multilib\]/,/Include/"'s/^#//' /etc/pacman.conf
echo ""
pacman -Syy
echo ""

#Instalar escritorio
echo "Selección del entorno de escritorio:"
echo ""
echo "1.- Kde"
echo "2.- Gnome"
echo "3.- Cinnamon"
echo "4.- Mate"
echo "5.- Deepin"
echo "6.- Budgie"
echo "7.- Ukui"
echo ""
while :
do
    read -p "Qué escritorio quieres instalar? " pEscritorio
    echo ""
    case $pEscritorio in
        1)
            echo "Instalando Kde"
            pacman -S --noconfirm plasma-desktop kscreen konsole dolphin kate breeze-gtk kde-gtk-config libappindicator-gtk3 plasma-nm plasma-pa ark okular kinfocenter kwalletmanager transmission-qt gwenview kipi-plugins spectacle kcolorchooser vlc konversation partitionmanager sddm sddm-kcm kdialog discover packagekit-qt5
            systemctl enable sddm.service
            break
            ;;
        2)
            echo "Instalando Gnome"
            pacman -S --noconfirm gnome
            systemctl enable gdm.service
            break
            ;;
        3)
            echo "Instalando Cinnamon"
            pacman -S --noconfirm lightdm lightdm-gtk-greeter cinnamon cinnamon-translations gnome-terminal
            systemctl enable lightdm.service
            break
            ;;
        4)
            echo "Instalando Mate"
            pacman -S --noconfirm mate mate-terminal pluma lightdm lightdm-gtk-greeter
            systemctl enable lightdm.service
            break
            ;;
        5)
            echo "Instalando Deepin"
            pacman -S --noconfirm deepin lightdm lightdm-gtk-greeter deepin-terminal deepin-editor
            sed -i 's/#greeter-session=example-gtk-gnome/greeter-session=lightdm-deepin-greeter/g' /etc/lightdm/lightdm.conf
            systemctl enable lightdm.service
            break
            ;;
        6)
            echo "Instalando Budgie"
            pacman -S --noconfirm budgie-desktop gnome-terminal lightdm lightdm-gtk-greeter gnome-terminal gnome-control-center
            sed -i 's/#greeter-session=example-gtk-gnome/greeter-session=lightdm-gtk-greeter/g' /etc/lightdm/lightdm.conf
            systemctl enable lightdm.service
            break
            ;;
        7)
            echo "Instalando Ukui"
            pacman -S --noconfirm ukui
            systemctl enable lightdm.service
            break
            ;;
        *)
            echo "Opción no válida, inténtalo de nuevo."
            ;;
    esac
done
echo ""

#Instalar navegador
echo "Selección del navegador:"
echo ""
echo "1.- Firefox"
echo "2.- Chromium"
echo "3.- Opera"
echo "4.- Ninguno"
echo ""
while :
do
    read -p "Qué navegador quieres instalar? " pNavegador
    echo ""
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
        3)
            echo "Instalando Opera"
            pacman -S --noconfirm opera
            break
            ;;
        4)
            break
            ;;
        *)
            echo "Opción no válida, inténtalo de nuevo."
            ;;
    esac
done
echo ""

#Instalar Bluetooth
read -p "Quieres instalar bluetooth? [s/n] " pBluetooth
if [ $pBluetooth = 's' ] || [ $pBluetooth = 'S' ]
then
    echo "Instalando Bluetooth"
    pacman -S --noconfirm bluez bluez-utils 
fi
echo ""

#Instalar Discord
read -p "Quieres instalar Discord? [s/n] " pDiscord
if [ $pDiscord = 's' ] || [ $pDiscord = 'S' ]
then
    echo "Instalando Discord"
    pacman -S --noconfirm discord
fi
echo ""

#Instalar Wine
read -p "Quieres instalar Wine? [s/n] " pWine
if [ $pWine = 's' ] || [ $pWine = 'S' ]
then
    echo "Instalando Wine, Dxvk y sus dependencias"
    pacman -S --noconfirm --needed wine-staging winetricks nvidia-dkms nvidia-utils lib32-nvidia-utils nvidia-settings vulkan-icd-loader lib32-vulkan-icd-loader giflib lib32-giflib libpng lib32-libpng libldap lib32-libldap gnutls lib32-gnutls mpg123 lib32-mpg123 openal lib32-openal v4l-utils lib32-v4l-utils libpulse lib32-libpulse libgpg-error lib32-libgpg-error alsa-plugins lib32-alsa-plugins alsa-lib lib32-alsa-lib libjpeg-turbo lib32-libjpeg-turbo sqlite lib32-sqlite libxcomposite lib32-libxcomposite libxinerama lib32-libxinerama libgcrypt lib32-libgcrypt ncurses lib32-ncurses opencl-icd-loader lib32-opencl-icd-loader libxslt lib32-libxslt libva lib32-libva gtk3 lib32-gtk3 gst-plugins-base-libs lib32-gst-plugins-base-libs
fi
echo ""

#Instalar Lutris
read -p "Quieres instalar Lutris? [s/n] " pLutris
if [ $pLutris = 's' ] || [ $pLutris = 'S' ]
then
    echo "Instalando Lutris"
    pacman -S --noconfirm lutris
fi
echo ""

echo "La instalación de paquetes ha finalizado."
echo ""

#Instalar Feral Gamemode
read -p "Quieres instalar Gamemode? [s/n] " pGamemode
if [ $pGamemode = 's' ] || [ $pGamemode = 'S' ]
then
    echo "Instalando Gamemode"
    pacman -S --noconfirm gamemode lib32-gamemode
fi
echo ""

# Enable services
echo "Activando el arranque automatico de la red..."
systemctl enable NetworkManager.service
echo ""

#Modificar swappiness
echo "Modificando el valor del Swapiness..."
echo "vm.swappiness=10" >> /etc/sysctl.d/99-swappiness.conf
echo ""

echo "Configuration completada. Ya puedes salir de chroot, teclea exit"
