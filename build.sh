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

if ! command -v inkscape >/dev/null
then
    echo  -e "=> 🙅 Please install inkscape\n"
    exit 1
fi

if ! command -v optipng >/dev/null
then
    echo  -e "=> 🙅 Please install optipng\n"
    exit 1
fi

if ! command -v svgo >/dev/null
then
    echo  -e "=> 🙅 Please install svgo\n"
    exit 1
fi

if [[ -z $1 ]]
then
    echo  -e "=> 🙅 Please give a valid parameter\n"
    exit 1
elif [[ $1 = "--all" ]]
then
    echo -e "=> 🔥 Warning this will delete the /build folder and recreate it entirely from /src (will take a while)\n"
    read -p "=> Continue? (yes/no) " continue

    if [[ $continue != yes ]]
    then
        echo -e "\n=> Abort"
        exit 0
    fi

    echo -e "\n=> Remove old build\n"

    rm -Rf "build"
    mkdir -p -v "build"

    cp -Rf "src" \
    "./build/svg"

    cp -Rf "src" \
    "./build/png"

    cd "./build/png"

    sed -i 's/.xxx/.png/g' links.txt

    echo -e "\n=> 👷 Export all SVG to PNG ..."
    find -name "*.svg" -o -name "*.SVG" | while read i;
    do
        echo -e "\n=> 🔨 Render ${i}\n"
    	inkscape -f "$i" -e "${i%.*}.png"

        echo -e "\n=> ✨ Optimize PNG\n"
    	optipng -o7 "${i%.*}.png"
    	rm "$i"
    done

    cd "../"

    sed -i 's/.xxx/.svg/g' ./svg/links.txt

    echo -e "\n=> ✨ Minimify all SVG ...\n"
    svgo -r -f svg
else
    echo -e "=> 🌠 Copy links.txt\n"

    cp -f "./src/links.txt" "./build/png/links.txt"
    sed -i 's/.xxx/.png/g' "./build/png/links.txt"

    cp -f "./src/links.txt" "./build/svg/links.txt"
    sed -i 's/.xxx/.svg/g' "./build/svg/links.txt"

    echo -e "=> 🔨 Render PNG file\n"
    inkscape -f "./src${1}.svg" -e "./build/png${1}.png"

    echo -e "\n=> ✨ Optimize PNG\n"
    optipng -o7 "./build/png${1}.png"

    echo -e "\n=> ✨ Minimify SVG"

    svgo -i "./src${1}.svg" -o "./build/svg${1}.svg"
fi
