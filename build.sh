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
##      -f, --file <string>  Svg file path to build. Must looks like "/cmd/sc_singlepage" (without file extension and "/src" prefix)
##      -a, --all            Delete the "/build" folder and recreate it entirely from "/src" [default: 0]
##      -w, --watch          Watch file changes [default: 0]
##      -l, --links          Generate "links.txt" files [default: 0]
##      -e, --oxt            Generate OXT extension archive [default: 0]

# CLInt GENERATED_CODE: start
# Default values
_all=0
_watch=0
_links=0
_oxt=0

# No-arguments is not allowed
[ $# -eq 0 ] && sed -ne 's/^## \(.*\)/\1/p' $0 && exit 1

# Converting long-options into short ones
for arg in "$@"; do
  shift
  case "$arg" in
"--file") set -- "$@" "-f";;
"--all") set -- "$@" "-a";;
"--watch") set -- "$@" "-w";;
"--links") set -- "$@" "-l";;
"--oxt") set -- "$@" "-e";;
  *) set -- "$@" "$arg"
  esac
done

function print_illegal() {
    echo Unexpected flag in command line \"$@\"
}

# Parsing flags and arguments
while getopts 'hawlef:' OPT; do
    case $OPT in
        h) sed -ne 's/^## \(.*\)/\1/p' $0
           exit 1 ;;
        a) _all=1 ;;
        w) _watch=1 ;;
        l) _links=1 ;;
        e) _oxt=1 ;;
        f) _file=$OPTARG ;;
        \?) print_illegal $@ >&2;
            echo "---"
            sed -ne 's/^## \(.*\)/\1/p' $0
            exit 1
            ;;
    esac
done
# CLInt GENERATED_CODE: end

###################################################
# CHECKS
###################################################

echo

if ! command -v cairosvg >/dev/null
then
    echo  -e "=> 🙅 Please install cairosvg\n"
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

if ! command -v parallel >/dev/null
then
    echo  -e "=> 🙅 Please install parallel\n"
    exit 1
fi

###################################################
# FUNCTIONS
###################################################

function render_icon() {
    # Mkdir folders

    mkdir -p $(dirname ./build/default/png${1}.png)
    mkdir -p $(dirname ./build/default/svg${1}.svg)
    mkdir -p $(dirname ./build/mate/png${1}.png)
    mkdir -p $(dirname ./build/mate/svg${1}.svg)

    # Build Normal icon

    echo -e "=> 🔨 Render PNG file\n"
    cairosvg "./src/default${1}.svg" -o "./build/default/png${1}.png"

    echo -e "\n=> ✨ Optimize PNG\n"
    optipng -o7 "./build/default/png${1}.png"

    echo -e "\n=> ✨ Minimify SVG"

    svgo -i "./src/default${1}.svg" -o "./build/default/svg${1}.svg"

    # Build MATE icon

    if test -f "./src/mate${1}.svg"; then # Check if MATE specific file exist
        echo -e "\n=> 🌠 Copy MATE icon\n"
        cp -f "./src/mate${1}.svg" "./build/mate/svg${1}.svg"
    else
        cp -f "./src/default${1}.svg" "./build/mate/svg${1}.svg"

        if ! fgrep -q -m 1 "${1}.svg" "./src/mate/exclude.txt"; then
            echo -e "\n=> 🍊 🍇 -> 🍏 Replace Ubuntu Colors by MATE Green\n"

            sed -i 's/e95420/88a05d/g' "./build/mate/svg${1}.svg"
            sed -i 's/E95420/88a05d/g' "./build/mate/svg${1}.svg"
            sed -i 's/77216f/88a05d/g' "./build/mate/svg${1}.svg"
            sed -i 's/77216F/88a05d/g' "./build/mate/svg${1}.svg"
        fi
    fi

    cp -f "./build/mate/svg${1}.svg" "./build/mate/png${1}.svg"

    echo -e "=> 🔨 Render MATE PNG file\n"
    cairosvg "./build/mate/png${1}.svg" -o "./build/mate/png${1}.png"
    rm "./build/mate/png${1}.svg"

    echo -e "\n=> ✨ Optimize MATE PNG\n"
    optipng -o7 "./build/mate/png${1}.png"

    echo -e "\n=> ✨ Minimify MATE SVG"

    svgo -i "./build/mate/svg${1}.svg" -o "./build/mate/svg${1}.svg"
}
export -f render_icon

function generate_links() {
    echo -e "\n=> 🌠 Copy links.txt\n"

    cp -f "./src/links.txt" "./build/default/png/links.txt"
    sed -i 's/.xxx/.png/g' "./build/default/png/links.txt"

    cp -f "./src/links.txt" "./build/default/svg/links.txt"
    sed -i 's/.xxx/.svg/g' "./build/default/svg/links.txt"

    cp -f "./build/default/png/links.txt" "./build/mate/png/links.txt"
    cp -f "./build/default/svg/links.txt" "./build/mate/svg/links.txt"

    echo -e "\n=> 🎉 Finish\n"
}

function generate_oxt() {
    echo "=> 📦 Zip icons"

    cd "build/default/svg"
    zip -r "images_yaru_svg.zip" *

    cd "../png"
    zip -r "images_yaru.zip" *

    cd "../../mate/svg"
    zip -r "images_yaru_mate_svg.zip" *

    cd "../png"
    zip -r "images_yaru_mate.zip" *

    cd "../../../"

    mv "build/default/png/images_yaru.zip" "dist/images_yaru.zip"
    mv "build/default/svg/images_yaru_svg.zip" "dist/images_yaru_svg.zip"
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
}

###################################################
# MAIN 
###################################################

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

    filenames=()

    while read -d $'\0' filename
    do
        filename=${filename#"./src/default"}
        filename=${filename%".svg"}
        filenames+=($filename)
    done < <(find "./src/default" -name "*.svg" -print0)

    parallel render_icon ::: "${filenames[@]}"

    generate_links
elif [[ $_watch = 1 ]];
then
    echo -e "=> 🔍 Lets watch file changes (abort with CTRL+C) ...\n"

    while true; do
        filename=$(inotifywait -r -q --event close_write --format %w%f ./)

        if [[ $filename == *links.txt ]]; then
            ./generate-links.sh
        elif [[ $filename == ./src/default/* ]]; then
            if [[ $filename == *.svg ]];
            then
                filename=${filename#"./src/default"}
                filename=${filename%".svg"}

                render_icon $filename

                echo
            fi
        elif [[ $filename == ./src/mate/* ]]; then
            if [[ $filename == *.svg ]];
            then
                filename=${filename#"./src/mate"}
                filename=${filename%".svg"}

                render_icon $filename

                echo
            fi
        fi
    done
elif [[ $_links = 1 ]];
then
    generate_links
elif [[ $_oxt = 1 ]];
then
    generate_oxt
elif [[ ! -z "$_file" ]]; then
    render_icon $_file
else
    echo -e "❌ Error, please provide a valid option\n"
fi
