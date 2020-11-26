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

## Build script
##
## usage: ./build.sh [options]
##
## options:
##      -f, --file <string>  Svg file path to build. Must looks like "/cmd/sc_singlepage" (without file ext and /src prefix)
##      -a, --all            Delete the /build folder and recreate it entirely from /src [default: 0]
##      -w, --watch          Watch file changes () [default: 0]

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

if ! command -v inotifywait >/dev/null
then
    echo  -e "=> 🙅 Please install inotify-tools\n"
    exit 1
fi

# CLInt GENERATED_CODE: start
# Default values
_all=0
_watch=0

# No-arguments is not allowed
[ $# -eq 0 ] && sed -ne 's/^## \(.*\)/\1/p' $0 && exit 1

# Converting long-options into short ones
for arg in "$@"; do
  shift
  case "$arg" in
"--file") set -- "$@" "-f";;
"--all") set -- "$@" "-a";;
"--watch") set -- "$@" "-w";;
  *) set -- "$@" "$arg"
  esac
done

function print_illegal() {
    echo Unexpected flag in command line \"$@\"
}

# Parsing flags and arguments
while getopts 'hawf:' OPT; do
    case $OPT in
        h) sed -ne 's/^## \(.*\)/\1/p' $0
           exit 1 ;;
        a) _all=1 ;;
        w) _watch=1 ;;
        f) _file=$OPTARG ;;
        \?) print_illegal $@ >&2;
            echo "---"
            sed -ne 's/^## \(.*\)/\1/p' $0
            exit 1
            ;;
    esac
done
# CLInt GENERATED_CODE: end

function render_icon() {
    echo -e "=> 🌠 Copy links.txt\n"

    cp -f "./src/links.txt" "./build/png/links.txt"
    sed -i 's/.xxx/.png/g' "./build/png/links.txt"

    cp -f "./src/links.txt" "./build/svg/links.txt"
    sed -i 's/.xxx/.svg/g' "./build/svg/links.txt"

    echo -e "=> 🔨 Render PNG file\n"
    inkscape -o "./build/png${1}.png" "./src${1}.svg"

    echo -e "\n=> ✨ Optimize PNG\n"
    optipng -o7 "./build/png${1}.png"

    echo -e "\n=> ✨ Minimify SVG"

    svgo -i "./src${1}.svg" -o "./build/svg${1}.svg"
}

if [[ $_all = 1 ]];
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
    	inkscape -o "${i%.*}.png" "$i"

        echo -e "\n=> ✨ Optimize PNG\n"
    	optipng -o7 "${i%.*}.png"
    	rm "$i"
    done

    cd "../"

    sed -i 's/.xxx/.svg/g' ./svg/links.txt

    echo -e "\n=> ✨ Minimify all SVG ...\n"
    svgo -r -f svg

elif [[ $_watch = 1 ]];
then
    echo -e "=> 🔍 Lets watch the files ...\n"

    while true; do
        filename=$(inotifywait -r -q --event close_write --format %w%f src/)
        if [[ $filename == *.svg ]];
        then
            filename=${filename#"src"}
            filename=${filename%".svg"}

            render_icon $filename

            echo
        elif [[ $filename == *links.txt ]];
        then
            ./generate-links.sh
        fi
    done
else
    render_icon $_file
fi
