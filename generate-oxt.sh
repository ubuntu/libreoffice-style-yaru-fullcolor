#!/bin/bash
#
# Legal Stuff:
#
# This file is free software; you can redistribute it and/or modify it under
# the terms of the GNU Lesser General Public License as published by the Free Software
# Foundation; version 3.
#
# This file is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public License for more
# details.
#
# You should have received a copy of the GNU Lesser General Public License along with
# this program; if not, see <https://www.gnu.org/licenses/lgpl-3.0.txt>

echo

echo "=> 📦 Zip icons"

cd "build/svg"

zip -r "images_yaru_svg.zip" *

cd "../png"

zip -r "images_yaru.zip" *

cd "../mate/svg"

zip -r "images_yaru_mate_svg.zip" *

cd "../png"

zip -r "images_yaru_mate.zip" *

cd "../../../"

mv "build/png/images_yaru.zip" "dist/images_yaru.zip"
mv "build/svg/images_yaru_svg.zip" "dist/images_yaru_svg.zip"
mv "build/mate/png/images_yaru_mate.zip" "dist/images_yaru_mate.zip"
mv "build/mate/svg/images_yaru_mate_svg.zip" "dist/images_yaru_mate_svg.zip"

mkdir -p -v "oxt/iconsets"
cp "dist/images_yaru.zip" \
"oxt/iconsets/images_yaru.zip"
cp "dist/images_yaru_svg.zip" \
"oxt/iconsets/images_yaru_svg.zip"
cp "dist/images_yaru_mate.zip" \
"oxt/iconsets/images_yaru_mate.zip"
cp "dist/images_yaru_mate_svg.zip" \
"oxt/iconsets/images_yaru_mate_svg.zip"

cd "oxt"

echo -e "\n=> 🎁 Create oxt\n"

zip -r "yaru-theme.zip" *

mv "yaru-theme.zip" "../dist/yaru-theme.oxt"

echo -e "\n=> 🎉 Oxt and zip generated!\n"
