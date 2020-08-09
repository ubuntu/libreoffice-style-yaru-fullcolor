#!/bin/bash

echo -e "\n=> 🔥 Removing Libreoffice style Yaru\n"

for dir in \
  /usr/share/libreoffice/share/config \
  /usr/lib/libreoffice/share/config \
  /usr/lib64/libreoffice/share/config \
  /usr/local/lib/libreoffice/share/config \
  /opt/libreoffice*/share/config; do
  [ -d "$dir" ] || continue
  sudo rm -f -v "$dir/images_yaru.zip"
done

echo -e "\n=> 🎉 Finish\n"
