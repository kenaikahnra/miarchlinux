#! /bin/bash

echo "Instalador de Arch de Gaizka"

#Establecer teclado español
loadkeys es

#Actualizar el reloj del sistema
timedatectl set-ntp true

# Filesystem mount warning
echo "A continuación se particionará el disco de la siguiente manera:"
echo "1 - 512Mib se montará en /boot/efi"
echo "2 - 2GiB se utilizará como swap"
echo "3 - 40Gib se montará en /"
echo "4 - el resto del disco se montará en /home"
read -p 'Continuar? [y/N]: ' fsok
if ! [ $fsok = 'y' ] && ! [ $fsok = 'Y' ]
then 
    echo "Edita el script para..."
    exit
fi

echo "Discos detectados:"
lsblk|grep disk|grep -v

echo ""
read -p "Escribe el nombre del disco donde se instalará Arch linux (todo el contenido será borrado) : " TARGET
echo "Borrando disco $TARGET"
wipefs -a /dev/$TARGET &>/dev/null

# Crear particiones
sed -e 's/\s*\([\+0-9a-zA-Z]*\).*/\1/' << EOF | fdisk /dev/$TARGET
  o # clear the in memory partition table
  n # new partition
  p # primary partition
  1 # partition number 1
    # default - start at beginning of disk 
  +512M # 512 MB boot parttion
  n # new partition
  p # primary partition
  2 # partition number 2
    # default, start immediately after preceding partition
  +2G # 8 GB swap partition
  n # new partition
  p # primary partition
  3 # partition number 3
    # default, start immediately after preceding partition
  +40G # 40 GB root partition
  4 # partion number 4
    # default, start immediately after preceding partition
    # default, extend partition to end of disk
  a # make a partition bootable
  1 # bootable partition is partition 1 -- /dev/sda1
  p # print the in-memory partition table
  w # write the partition table
  q # and we're done
EOF

#Formatear partición /boot
mkfs.fat -F32 /dev/${TARGET}1

#Formatear partición [swap]
mkswap /dev/${TARGET}2
swapon /dev/${TARGET}2

#Formatear partición / y /home
mkfs.ext4 /dev/${TARGET}3
mkfs.ext4 /dev/${TARGET}4

# Initate pacman keyring
pacman-key --init
pacman-key --populate archlinux
pacman-key --refresh-keys

#Montar partición /
mount /dev/${TARGET}3 /mnt

#Montar partición /home si la hubiera
mkdir /mnt/home
mount /dev/${TARGET}4 /mnt

# Install Arch Linux
echo "Instalando Arch Linux" 
pacstrap /mnt base base-devel linux linux-firmware grub os-prober efibootmgr sudo nano intel-ucode xorg xorg-xinit nvidia nvidia-utils networkmanager ntfs-3g plasma-desktop sddm sddm-kcm user-manager konsole dolphin firefox kate breeze-gtk kde-gtk-config libappindicator-gtk3
plasma-nm plasma-pa ark okular kinfocenter kwalletmanager transmission-qt gwenview kipi-plugins spectacle kcolorchooser vlc konversation bluez bluez-utils discord wine-staging nvidia-dkms nvidia-utils lib32-nvidia-utils nvidia-settings vulkan-icd-loader lib32-vulkan-icd-loader giflib lib32-giflib libpng lib32-libpng libldap lib32-libldap gnutls lib32-gnutls mpg123 lib32-mpg123 openal lib32-openal v4l-utils lib32-v4l-utils libpulse lib32-libpulse libgpg-error lib32-libgpg-error alsa-plugins lib32-alsa-plugins alsa-lib lib32-alsa-lib libjpeg-turbo lib32-libjpeg-turbo sqlite lib32-sqlite libxcomposite lib32-libxcomposite libxinerama lib32-libgcrypt libgcrypt lib32-libxinerama ncurses lib32-ncurses opencl-icd-loader lib32-opencl-icd-loader libxslt lib32-libxslt libva lib32-libva gtk3 lib32-gtk3 gst-plugins-base-libs lib32-gst-plugins-base-libs vulkan-icd-loader lib32-vulkan-icd-loader lutris git

#Generar fichero fstab
genfstab -U /mnt >> /mnt/etc/fstab

# Copy post-install system configuration script to new /root
cp -rfv post-install.sh /mnt/root
chmod a+x /mnt/root/post-install.sh

# Chroot into new system
echo "Tras chrootear en el recien instalado Arch Linux, ejecuta ./post-install.sh para continuar con la instalación"
echo "Pulsa cualquier tecla para chroot..."
read tmpvar
arch-chroot /mnt

# Finish
echo "Si post-install.sh se ha ejecutado correctamente, ahora tienes instalado un sistema Arch linux completamente funcional."
echo "Lo unico que falta es reiniciar en tu nuevo sistema."
echo "Una vez que reinicies recuerda instalar el AUR Helper Yay y gamemode ejecutando"
echo "git clone https://aur.archlinux.org/yay-git.git"
echo "cd yay-git"
echo "makepkg -si"
echo "yay gamemode lib32-gamemode"
echo "Recuerda tambien eliminar el fichero post-install.sh de la carpeta /root"
echo "Pulsa cualquier tecla para reiniciar or Ctrl+C para cancelar..."
read tmpvar
reboot
