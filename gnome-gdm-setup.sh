# Instala GNOME minimal
nala install gnome-shell

# Instala GDM 
nala install gdm

systemctl enable gdm.service

# Configura autologin no GDM
sed -i 's/#AutomaticLoginEnable=true/AutomaticLoginEnable=true/' /etc/gdm/custom.conf
sed -i 's/#AutomaticLogin=user1/AutomaticLogin=joao/' /etc/gdm/custom.conf

gsettings set org.gnome.desktop.interface gtk-theme "Adwaita"

nala install gnome-tweaks