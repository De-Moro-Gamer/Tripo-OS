#!/bin/bash

# Configuração
LFS=/mnt/lfs
ARCH=x86_64
SRC=/src

# Funções
download_sources(){

# Pacotes
PACKAGES="snapd
          flatpak
          appimagetool
          winehq-stable 
          firefox
          gnome-minimal
          glibc
          linux  
          gcc
          nala"

# Efetua downloads
for package in $PACKAGES; do
  case "$package" in

    snapd )
      wget -P $DIR https://github.com/snapcore/snapd/releases/download/2.51/snapd_2.51_amd64.tar.xz ;;

    flatpak )
      wget -P $DIR http://flathub.org/repo/appstream/org.freedesktop.Platform.flatpak.BaseApp/x86_64/stable/1.12.9/org.freedesktop.Platform.flatpak.BaseApp-1.12.9.x86_64.flatpak ;;
    
    appimagetool )  
      wget -P $DIR https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-x86_64.AppImage ;;

    winehq-stable )
      wget -P $DIR https://dl.winehq.org/wine-builds/ubuntu/pool/main/w/wine-builds/winehq-stable-ubuntu-5.0.3.tar.gz ;;

    firefox )
      wget -P $DIR https://download-installer.cdn.mozilla.net/pub/firefox/releases/108.0/linux-x86_64/en-US/firefox-108.0.tar.bz2 ;;

    gnome-minimal )
      wget -P $DIR http://ftp.acc.umu.se/pub/gnome/core/3.38/3.38.4/sources/gnome-minimal-3.38.4.tar.xz ;;

    glibc )  
      wget -P $DIR http://www.linuxfromscratch.org/lfs/downloads/glibc-2.35.tar.xz ;;

    linux )
      wget -P $DIR http://www.linuxfromscratch.org/lfs/downloads/linux-5.15.tar.xz ;;

    gcc )
      wget -P $DIR http://www.linuxfromscratch.org/lfs/downloads/gcc-11.2.0.tar.xz ;;

    nala )
      wget -P $DIR https://github.com/volitank/nala/releases/download/v1.7.0/nala-1.7.0.tar.gz ;;

  esac
done

}

build_package(){

  cd "$1"

  ./configure --prefix=/mnt/lfs && make -j4 && make install

  if [ $? -ne 0 ]; then
    echo "Erro ao compilar $1"
    exit 1
  fi

}

configure_system(){

  # Instala gerenciador de pacotes
  pacstrap /mnt/lfs apt || { echo "Falha ao instalar pacstrap"; exit 1; }

  # Adiciona repositórios extras
  echo "deb http://archive.ubuntu.com/ubuntu/ jammy main universe" >> /mnt/lfs/etc/apt/sources.list

  # Atualiza e instala pacotes
  arch-chroot /mnt/lfs apt update
  if [ $? -ne 0 ]; then 
    echo "Erro ao atualizar repositórios"
    exit 1
  fi
  # Repositorio Flatpak
  arch-chroot /mnt/lfs flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

  # Repositorio AppImage
  wget -P /mnt/lfs/opt/ https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-x86_64.AppImage

  # Repositorios DEB 
  echo "deb http://archive.ubuntu.com/ubuntu/ jammy main universe" >> /mnt/lfs/etc/apt/sources.list

  # Repositorio Nala  
  curl https://raw.githubusercontent.com/volitank/nala/master/scripts/install.sh | bash

  # Repositorios GNOME
  echo "deb http://archive.ubuntu.com/ubuntu/ jammy main universe" >> /etc/apt/sources.list  

  # Repositorio Firefox
  echo "deb http://archive.ubuntu.com/ubuntu/ jammy main universe" >> /etc/apt/sources.list

  # Repositorio do Wine
  echo "deb https://dl.winehq.org/wine-builds/ubuntu/ jammy main" | tee -a /etc/apt/sources.list.d/winehq.list

  # Repositorio do RPM 
  echo "[rpm]
  name=RPM repository
  baseurl=http://rpms.famillecollet.com/enterprise/7/remi/x86_64/
  enabled=1
  gpgcheck=1
  gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-remi" | tee -a /etc/yum.repos.d/remi.repo

  # Repositorio do Snap
  echo "types: [snap]" | tee -a /etc/apt/sources.list.d/snapcraft.list

  arch-chroot /mnt/lfs apt install -y gnome-shell firefox

  # Instala snap 
  arch-chroot /mnt/lfs apt install snapd -y
  arch-chroot /mnt/lfs systemctl enable --now snapd.socket
  arch-chroot /mnt/lfs /usr/bin/snap wait system seed.loaded
  arch-chroot /mnt/lfs snap install hello

  # Instala flatpak
  arch-chroot /mnt/lfs apt install flatpak -y
  arch-chroot /mnt/lfs flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
  arch-chroot /mnt/lfs flatpak install flathub com.spotify.Client

  # Instala AppImage
  arch-chroot /mnt/lfs apt install libfuse2 -y
  arch-chroot /mnt/lfs wget https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-x86_64.AppImage
  arch-chroot /mnt/lfs chmod +x appimagetool-x86_64.AppImage

  # Instala deb
  echo "deb http://archive.ubuntu.com/ubuntu/ jammy main universe" >> /etc/apt/sources.list
  arch-chroot /mnt/lfs apt update 
  arch-chroot /mnt/lfs apt install gdebi -y
  arch-chroot /mnt/lfs gdebi /caminho/para/pacote.deb

  # Instala rpm
  arch-chroot /mnt/lfs apt install rpm -y
  arch-chroot /mnt/lfs rpm -i /caminho/para/pacote.rpm

  # Instala wine
  arch-chroot /mnt/lfs apt install winehq-stable -y

  if [ $? -ne 0 ]; then
    echo "Erro ao instalar pacotes adicionais"
    exit 1
  fi

  # Cria usuario
  arch-chroot /mnt/lfs useradd -m tripo-os || { echo "Falha ao criar usuário"; exit 1; }

  # Configura rede
  echo "iface eth0 inet dhcp" > /mnt/lfs/etc/network/interfaces || { echo "Falha rede"; exit 1; }

  # Outras configuracoes
  echo "pts/0" >> /mnt/lfs/etc/securetty || { echo "Falha conf"; exit 1; }

}
for pkg in glibc gcc coreutils linux; do
  build_package $SRC/$pkg
done

configure_system

# Gera ISO

# Cria diretorio para a imagem ISO
mkdir /mnt/lfs/iso

# Copia arquivos do sistema LFS 
cp -R /mnt/lfs/* /mnt/lfs/iso/

mkisofs -o /mnt/lfs/iso/lfs-custom.iso \
  -eltorito-alt-boot \
  -e images/efiboot.img -no-emul-boot \
  -isohybrid-gpt-basdat \
  -R -J -v -V "LFS Custom" \
  /mnt/lfs/iso

# Verifica tamanho da ISO 
iso_size=$(du -h /mnt/lfs/iso/lfs-custom.iso | cut -f1)
echo "ISO de $iso_size gerada em /mnt/lfs/iso/lfs-custom.iso"
echo "ISO gerada em $LFS/iso/lfs-custom.iso"