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
    # Build Normal icon

    echo -e "=> 🔨 Render PNG file\n"
    inkscape -o "./build/default/png${1}.png" "./src/default${1}.svg"

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
    inkscape -o "./build/mate/png${1}.png" "./build/mate/png${1}.svg"
    rm "./build/mate/png${1}.svg"

    echo -e "\n=> ✨ Optimize MATE PNG\n"
    optipng -o7 "./build/mate/png${1}.png"

    echo -e "\n=> ✨ Minimify MATE SVG"

    svgo -i "./build/mate/svg${1}.svg" -o "./build/mate/svg${1}.svg"
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
    mkdir -p -v "build/default"
    mkdir -p -v "build/mate"

    cp -Rf "src/default" "./build/default/svg"
    cp -Rf "src/default" "./build/default/png"
    cp -Rf "src/default" "./build/mate/svg"

    # Build Normal icons

    cd "./build/default/png"

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

    # Build MATE icons

    cd "../../"

    cp "./src/mate/exclude.txt" "build/mate/svg/"

    cd "./build/mate/svg/"

    echo -e "\n=> 🍊 🍇 -> 🍏 Replace Ubuntu Colors by MATE Green ..."
    find -name "*.svg" -o -name "*.SVG" | while read i;
    do
        i=${i#"./"}

        if ! fgrep -q -m 1 "/${i}" "exclude.txt"; then
            sed -i 's/e95420/88a05d/g' $i
            sed -i 's/E95420/88a05d/g' $i
            sed -i 's/77216f/88a05d/g' $i
            sed -i 's/77216F/88a05d/g' $i
        fi
    done

    cd "../../.."

    cp -RT "src/mate/" "./build/mate/svg/"
    rm "./build/mate/svg/exclude.txt"

    cd "./build/mate"

    cp -Rf "svg" "./png"

    cd "./png"

    sed -i 's/.xxx/.png/g' links.txt

    echo -e "\n=> 👷 Export all MATE SVG to PNG ..."
    find -name "*.svg" -o -name "*.SVG" | while read i;
    do
        echo -e "\n=> 🔨 Render ${i}\n"
    	inkscape -o "${i%.*}.png" "$i"

        echo -e "\n=> ✨ Optimize PNG\n"
    	optipng -o7 "${i%.*}.png"
    	rm "$i"
    done

    cd "../../"

    sed -i 's/.xxx/.svg/g' ./mate/svg/links.txt

    echo -e "\n=> ✨ Minimify all MATE SVG ...\n"
    svgo -r -f mate/svg

elif [[ $_watch = 1 ]];
then
    echo -e "=> 🔍 Lets watch the files ...\n"

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
else
    render_icon $_file
fi
