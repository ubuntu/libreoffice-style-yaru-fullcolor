#!/bin/bash

cp "build/images_yaru.zip" \
"oxt/iconsets/images_yaru.zip"

cd "oxt"

rm "yaru-theme.oxt"

zip -r "yaru-theme.zip" *

mv "yaru-theme.zip" "../yaru-theme.oxt"
