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
# POPULATE ACCENT COLORS
###################################################

accents=( "default" )

while read line; do
    if [ "$line" = "" ] || [[ "$line" =~ ^#.*  ]]
    then
        continue
    fi

    IFS=' '
    read -ra splitedline <<< "$line"
    if [[ ${#splitedline[@]} > 2 ]] || [[ ${#splitedline[@]} < 2 ]]; then
        echo "Error line $n: Malformed line '$line'"
    else
        accents+=( "${line}" )
    fi
done < "src/accents.txt"

###################################################
# FUNCTIONS
###################################################

function render_icon() {
    variant_color=( $2 )
    accent_name=${variant_color[0]}
    accent_color=${variant_color[1]}

    # Mkdir folders

    mkdir -p $(dirname ./build/${accent_name}/png${1}.png)
    mkdir -p $(dirname ./build/${accent_name}/svg${1}.svg)

    if [[ $accent_name == "default" ]]; then
        # Build default icon

        echo -e "=> 🔨 Render '${1}'"

        cp -f "./src/default${1}.svg" "./build/default/svg${1}.svg"
        svgo "./build/default/svg${1}.svg"  &>/dev/null
        # replace placeholder colors
        sed -i 's/0ff/e95420/g' "./build/default/svg${1}.svg"
        sed -i 's/0f0/77216f/g' "./build/default/svg${1}.svg"

        # Render PNG
        cairosvg "./build/default/svg${1}.svg" -o "./build/default/png${1}.png"  &>/dev/null
        optipng -o7 "./build/default/png${1}.png"  &>/dev/null
    else
        # Build accented icons

        echo -e "=> 🔨 Render '${1}' - ${accent_name} accented "

        # Check if accented specific file exist
        if test -f "./src/accented${1}.svg"; then
            cp -f "./src/accented${1}.svg" "./build/${accent_name}/svg${1}.svg"
        else
            cp -f "./src/default${1}.svg" "./build/${accent_name}/svg${1}.svg"
        fi

        svgo "./build/${accent_name}/svg${1}.svg"  &>/dev/null
        # replace placeholder colors
        sed -i "s/0ff/${accent_color}/g" "./build/${accent_name}/svg${1}.svg"
        sed -i "s/0f0/${accent_color}/g" "./build/${accent_name}/svg${1}.svg"

        # Render PNG
        cairosvg "./build/${accent_name}/svg${1}.svg" -o "./build/${accent_name}/png${1}.png"  &>/dev/null
        optipng -o7 "./build/${accent_name}/png${1}.png" &>/dev/null
    fi
}
export -f render_icon

function generate_links() {
    echo -e "=> 🌠 Copy and format links.txt in build\n"

    for variant_color in "${accents[@]}"; do
        variant_color=( $variant_color )
        accent_name=${variant_color[0]}
        
        cp -f "./src/links.txt" "./build/${accent_name}/png/links.txt"
        sed -i 's/.xxx/.png/g' "./build/${accent_name}/png/links.txt"

        cp -f "./src/links.txt" "./build/${accent_name}/svg/links.txt"
        sed -i 's/.xxx/.svg/g' "./build/${accent_name}/svg/links.txt"
    done

    echo -e "=> 🎉 Finish\n"
}

function generate_oxt() {
    echo "=> 📦 Zip icons"

    mkdir -p -v "oxt/iconsets"

    for variant_color in "${accents[@]}"; do
        variant_color=( $variant_color )
        accent_name=${variant_color[0]}

        if [[ $accent_name == "default" ]]; then
            theme_name="yaru"
        else
            theme_name="yaru_${accent_name}"
        fi

        cd "build/${accent_name}/svg"
        zip -r "images_${theme_name}_svg.zip" *

        cd "../png"
        zip -r "images_${theme_name}.zip" *

        cd "../../.."

        mv "build/${accent_name}/png/images_${theme_name}.zip" "dist/images_${theme_name}.zip"
        mv "build/${accent_name}/svg/images_${theme_name}_svg.zip" "dist/images_${theme_name}_svg.zip"

        cp -f "dist/images_${theme_name}.zip" "oxt/iconsets/images_${theme_name}.zip"
        cp -f "dist/images_${theme_name}_svg.zip" "oxt/iconsets/images_${theme_name}_svg.zip"
    done

    cd "oxt"

    echo -e "\n=> 🎁 Create oxt\n"

    zip -r "yaru-theme.zip" *
    cd ..
    mv "oxt/yaru-theme.zip" "dist/yaru-theme.oxt"
    rm oxt/iconsets/*

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

    parallel render_icon ::: "${filenames[@]}" ::: "${accents[@]}"

    generate_links
elif [[ $_watch = 1 ]];
then
    echo -e "=> 🔍 Lets watch file changes (abort with CTRL+C) ...\n"

    while true; do
        filename=$(inotifywait -r -q --event close_write --format %w%f ./src/)

        if [[ $filename == ./src/links.txt ]]; then
            generate_links
        elif [[ $filename == ./src/* ]]; then
            if [[ $filename == *.svg ]];
            then
                if [[ $filename == ./src/default/* ]]; then
                    filename=${filename#"./src/default"}
                elif [[ $filename == ./src/accented/* ]]; then
                    filename=${filename#"./src/accented"}
                fi

                filename=${filename%".svg"}

                parallel render_icon ::: "${filename}" ::: "${accents[@]}"

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
    parallel render_icon ::: "${_file}" ::: "${accents[@]}"
else
    echo -e "❌ Error, please provide a valid option\n"
fi
