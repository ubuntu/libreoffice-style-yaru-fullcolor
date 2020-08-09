#!/bin/bash

echo

cd "build"

echo "=> 📦 Zip icons"

zip -r -q "images_yaru.zip" *

cd "../"

mv "build/images_yaru.zip" "images_yaru.zip"

cp "images_yaru.zip" \
"oxt/iconsets/images_yaru.zip"

cd "oxt"

echo -e "\n=> 🎁 Create oxt\n"

zip -r "yaru-theme.zip" *

mv "yaru-theme.zip" "../yaru-theme.oxt"

echo -e "\n=> 🎉 Finish\n"
