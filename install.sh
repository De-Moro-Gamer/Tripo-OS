#!/bin/bash

# Atualiza e instala pacotes necessários no Ubuntu
sudo apt update
sudo apt install -y git wget bc pkg-config curl unzip nala

# Faz download e compila as ferramentas do LFS
git clone git://git.kernel.org/pub/scm/libs/klibc/klibc.git
cd klibc
make defconfig
make
sudo make install
cd .. 

wget http://www.linuxfromscratch.org/lfs/view/stable/wget-list
wget -i wget-list

# Cria partições e sistemas de arquivos para o LFS
sudo mkfs.ext4 /dev/sdb1
sudo mkswap /dev/sdb2
sudo swapon /dev/sdb2  
sudo mount /dev/sdb1 /mnt/lfs
sudo mkdir -pv /mnt/lfs/sources

# Instala pacotes essenciais no LFS
sudo chroot /mnt/lfs /tools/bin/env -i \
    HOME=/root \
    TERM="$TERM" \
    PS1='\u:\w\$ ' \
    PATH=/bin:/usr/bin:/sbin:/usr/sbin:/tools/bin \
    /tools/bin/bash --login +h -c "cd /sources && echo 'Instalando pacotes essenciais...' &&
wget http://www.linuxfromscratch.org/lfs/view/stable/chapter05/coreutils-8.32.tar.xz &&  
tar -xf coreutils-*.tar.xz &&
cd coreutils* &&  
./configure --prefix=/tools &&   
make -j$(nproc) &&
make install &&
cd .. && 
rm -rf coreutils*"

# Compila e instala o GCC no LFS
sudo chroot /mnt/lfs /tools/bin/env -i \
    HOME=/root \
    TERM="$TERM" \
    PS1='\u:\w\$ ' \ 
    PATH=/bin:/usr/bin:/sbin:/usr/sbin:/tools/bin \
    /tools/bin/bash --login +h -c "wget https://ftp.gnu.org/gnu/gcc/gcc-10.2.0/gcc-10.2.0.tar.xz &&
tar -xf gcc-*.tar.xz &&   
cd gcc-10.2.0 &&
./contrib/download_prerequisites &&
cd .. &&   
mkdir gcc-build &&
cd gcc-build &&   
../gcc-10.2.0/configure --prefix=/tools --enable-languages=c,c++ --without-headers && 
make -j$(nproc) &&
make install &&  
cd .. &&
rm -rf gcc*"

# Instala o LFS em /mnt/lfs
sudo chroot /mnt/lfs /tools/bin/env -i \
    HOME=/root \
    TERM="$TERM" \
    PS1='\u:\w\$ ' \
    PATH=/bin:/usr/bin:/sbin:/usr/sbin:/tools/bin \
    /tools/bin/bash --login +h -c "export LFS=/mnt/lfs &&
/tools/bin/bash /sources/lfs-book-11.1-aarch64-systemd/chapter05/chapter05.sh &&
/tools/bin/bash /sources/lfs-book-11.1-aarch64-systemd/chapter06/chapter06.sh"

# Instala o GNOME minimalista no LFS
sudo chroot /mnt/lfs /usr/bin/env -i \
    HOME=/root \
    TERM="$TERM" \
    PS1='\u:\w\$ ' \ 
    PATH=/bin:/usr/bin:/sbin:/usr/sbin \
    /bin/bash --login +h -c "pacman -Syu --noconfirm &&
pacman -S --noconfirm gdm gnome-shell gnome-terminal networkmanager"

# Habilita suporte a snap, flatpak, appimage e wine no LFS  
sudo chroot /mnt/lfs /usr/bin/env -i \
    HOME=/root \
    TERM="$TERM" \
    PS1='\u:\w\$ ' \
    PATH=/bin:/usr/bin:/sbin:/usr/sbin \
    /bin/bash --login +h -c "pacman -S --noconfirm snapd flatpak appimagelauncher wine"

# Instala nala e adiciona PPAs comuns no Ubuntu
sudo apt install nala -y  
nala update
nala upgrade -y
nala install software-properties-common
add-apt-repository ppa:alexlarsson/flatpak -y
add-apt-repository ppa:obsproject/obs-studio -y

# Gera ISO do LFS
sudo chroot /mnt/lfs /usr/bin/env -i \
    HOME=/root \ 
    TERM="$TERM" \
    PS1='\u:\w\$ ' \
    PATH=/bin:/usr/bin:/sbin:/usr/sbin \
    /bin/bash --login +h -c "cd / &&
mkisofs -R -b boot/grub/efi.img -no-emul-boot \
    -iso-level 3 -rock -joliet-long -o /home/$SUDO_USER/lfs.iso ."

# Desmonta partições 
sudo umount /mnt/lfs/dev/pts  
sudo umount /mnt/lfs/dev
sudo umount /mnt/lfs/run
sudo umount /mnt/lfs/proc
sudo umount /mnt/lfs/sys
sudo umount /mnt/lfs

# Instala o LFS em /dev/sdb
sudo mkfs.ext4 /dev/sdb1
sudo mkswap /dev/sdb2  
sudo swapon /dev/sdb2
sudo mount /dev/sdb1 /mnt/lfs  
sudo mkdir -pv /mnt/lfs/sources
sudo cp lfs.iso /mnt/lfs/sources/

sudo chroot /mnt/lfs /usr/bin/env -i \
    HOME=/root \
    TERM="$TERM" \ 
    PS1='\u:\w\$ ' \
    PATH=/bin:/usr/bin:/sbin:/usr/sbin \
    /bin/bash --login +h -c "mkdir /cdrom && mount -o loop /sources/lfs.iso /cdrom &&
/cdrom/install.sh && reboot"  

sudo umount /mnt/lfs

echo "LFS instalado em /dev/sdb e ISO gerada em ~/lfs.iso"