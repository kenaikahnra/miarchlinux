#!/bin/bash

clear
echo "Instalador de Arch de Gaizka"
echo ""

#Actualizar el reloj del sistema
timedatectl set-ntp true

#Seleccion de disco
echo "Discos detectados:"
echo ""
lsblk
echo ""
read -p "Escribe el nombre del disco donde quieres instalar Arch linux (todo el contenido será borrado): " TARGET
export TARGET
read -p "Estas seguro de que deseas borrar todo el contenido de $TARGET? [s/n]: " pBorrado
if ! [ $pBorrado = 's' ] && ! [ $pBorrado = 'S' ]
then 
    echo "Saliendo del instalador."
    exit
fi
wipefs -a /dev/$TARGET &>/dev/null
read -p "Cuánto espacio (en GiB) quieres dedicar a la partición raiz? para el sistema operativo? " pEspacio

#Información particionado
echo ""
echo "A continuación se particionará el disco de la siguiente manera:"
echo ""
echo "1 - 512Mib - se montará en /boot/efi"
echo "2 - 2GiB - se utilizará como swap"
echo "3 - ${pEspacio}Gib - se montará en /"
echo "4 - el resto del disco se montará en /home"
echo ""
read -p 'Continuar? [s/n]: ' fsok
if ! [ $fsok = 's' ] && ! [ $fsok = 'S' ]
then 
    echo "Edita el script para modificar las particiones."
    exit
fi

echo ""

# Crear particiones
echo "Creando particiones..."
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
  +${pEspacio}G # root partition
  n # new partition
  p # primary partition
  4 # partion number 4
    # default, start immediately after preceding partition
    # default, extend partition to end of disk
  a # make a partition bootable
  1 # bootable partition is partition 1 -- /dev/sda1
  p # print the in-memory partition table
  w # write the partition table
  q # and we're done
EOF
echo ""

echo "Formateando particiones..."
#Formatear partición /boot
mkfs.fat -F32 /dev/${TARGET}1

#Formatear partición [swap]
mkswap /dev/${TARGET}2
swapon /dev/${TARGET}2

#Formatear partición / y /home
mkfs.ext4 -F /dev/${TARGET}3
mkfs.ext4 -F /dev/${TARGET}4

#Montar partición /
mount /dev/${TARGET}3 /mnt

#Montar partición /home si la hubiera
mkdir /mnt/home
mount /dev/${TARGET}4 /mnt/home

echo "Particiones creadas:"
echo ""
lsblk /dev/$TARGET
echo ""
echo "Las particiones se han creado correctamente. Pulsa cualquier tecla para empezar la instalación."
read tmpvar
echo ""

# Install Arch Linux
echo "Instalando el sistema base..."
pacman -S --noconfirm reflector
reflector -c "ES" -f 12 -l 10 -n 12 --save /etc/pacman.d/mirrorlist
pacstrap /mnt base base-devel linux linux-firmware grub os-prober efibootmgr nano intel-ucode xorg xorg-xinit nvidia nvidia-utils networkmanager ntfs-3g git xdg-user-dirs reflector
echo ""

#Generar fichero fstab
echo "Generando fichero fstab"
genfstab -U /mnt >> /mnt/etc/fstab
echo ""

# Copiar fichero post-install.sh al nuevo /root
cp -rfv post-install.sh /mnt
chmod a+x /mnt/post-install.sh

# Entrar como root al nuevo sistema
echo ""
echo "La instalación del sistema base ha finalizado correctamente."
echo "Vas a entrar como root en tu nuevo Arch Linux, una vez dentro ejecuta ./post-install.sh para continuar con la instalación."
echo "Pulsa cualquier tecla para continuar."
read tmpvar
arch-chroot /mnt

# Finish
clear
echo "Si post-install.sh se ha ejecutado correctamente, ahora tienes instalado un sistema Arch linux completamente funcional."
echo ""
echo "Ya puedes reiniciar el sistema y disfrutar de la experiencia de Arch Linux."
echo "Recuerda eliminar el fichero post-install.sh de la carpeta /"
echo ""
