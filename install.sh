#!/bin/bash

echo -e "\n=> 🔥 Deleting old install\n"

for dir in \
  /usr/share/libreoffice/share/config \
  /usr/lib/libreoffice/share/config \
  /usr/lib64/libreoffice/share/config \
  /usr/local/lib/libreoffice/share/config \
  /opt/libreoffice*/share/config; do
  [ -d "$dir" ] || continue
  sudo rm -f -v "$dir/images_yaru.zip"
done

echo -e "\n=> 📥 Installing Libreoffice style Yaru\n"

sudo mkdir -p -v "/usr/share/libreoffice/share/config"
sudo cp -v "images_yaru.zip" "/usr/share/libreoffice/share/config/images_yaru.zip"

for dir in \
    /usr/lib64/libreoffice/share/config \
    /usr/lib/libreoffice/share/config \
    /usr/local/lib/libreoffice/share/config \
    /opt/libreoffice*/share/config; do
        [ -d "$dir" ] || continue
        sudo ln -sf -v "/usr/share/libreoffice/share/config/images_yaru.zip" "$dir"
done

echo -e "\n=> 🎉 Finish\n"
