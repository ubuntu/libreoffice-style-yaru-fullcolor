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
##      -z, --zip            Generate ZIP archives [default: 0]
##      -e, --oxt            Generate OXT extension archives [default: 0]

set -e

# CLInt GENERATED_CODE: start
# Default values
_all=0
_watch=0
_links=0
_zip=0
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
"--zip") set -- "$@" "-z";;
"--oxt") set -- "$@" "-e";;
  *) set -- "$@" "$arg"
  esac
done

function print_illegal() {
    echo Unexpected flag in command line \"$@\"
}

# Parsing flags and arguments
while getopts 'hawlzef:' OPT; do
    case $OPT in
        h) sed -ne 's/^## \(.*\)/\1/p' $0
           exit 1 ;;
        a) _all=1 ;;
        w) _watch=1 ;;
        l) _links=1 ;;
        z) _zip=1 ;;
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
# POPULATE VARIANTS COLORS
###################################################

function read_map_file() {
    local line
    local splitedline
    local n=0

    while IFS= read -r line; do
        n=$((n+1))
        [[ -z "$line" || "$line" =~ ^# ]] && continue

        read -ra splitedline <<< "$line"
        if (( ${#splitedline[@]} != 2 )); then
            echo "Error in \"$1\": $line (line $n)" >&2
            exit 1
        fi
        printf '%s\n' "$line"
    done < $1
}

output=$(read_map_file "src/accents.txt")
mapfile -t accents <<< "$output"

output=$(read_map_file "src/brightness.txt")
mapfile -t brightness <<< "$output"

# Should be an array of:
# variant_name accent_color brightness_color
variants=()

for accent in "${accents[@]}"; do
    accent=( $accent )
    accent_name=${accent[0]}
    accent_color=${accent[1]}

    for bness in "${brightness[@]}"; do
        bness=( $bness )
        brightness_name=${bness[0]}
        brightness_color=${bness[1]}

        variant_name=''

        if [[ $brightness_name == 'default' ]]; then
            variant_name=$accent_name
        elif [[ $accent_name == 'default' && $brightness_name != 'default' ]]; then
            variant_name=$brightness_name
        else
            variant_name="$accent_name-$brightness_name"
        fi

        variants+=( "$variant_name $accent_color $brightness_color" )
    done
done

###################################################
# FUNCTIONS
###################################################

function check_deps() {
    missing_deps=False
    params=( "$@" )

    if [[ " ${params[*]} " =~ "cairosvg" ]]; then
        if ! command -v cairosvg >/dev/null
        then
            echo  -e "=> 🙅 Please install cairosvg"
            missing_deps=True
        fi
    fi

    if [[ " ${params[*]} " =~ "optipng" ]]; then
        if ! command -v optipng >/dev/null
        then
            echo  -e "=> 🙅 Please install optipng"
            missing_deps=True
        fi
    fi

    if [[ " ${params[*]} " =~ "scour" ]]; then
        if ! command -v scour >/dev/null
        then
            echo  -e "=> 🙅 Please install scour"
            missing_deps=True
        fi
    fi

    if [[ " ${params[*]} " =~ "inotifywait" ]]; then
        if ! command -v inotifywait >/dev/null
        then
            echo  -e "=> 🙅 Please install inotify-tools"
            missing_deps=True
        fi
    fi

    if [[ " ${params[*]} " =~ "parallel" ]]; then
        if ! command -v parallel >/dev/null
        then
            echo  -e "=> 🙅 Please install parallel"
            missing_deps=True
        fi
    fi

    if [[ $missing_deps == True ]]; then
        echo
        exit 1
    fi
}
export -f check_deps

function render_icon() {
    check_deps "cairosvg" "scour" "optipng"

    variant_color=( $2 )
    variant_name=${variant_color[0]}
    accent_color=${variant_color[1]}
    brightness_color=${variant_color[2]}

    # Mkdir folders

    mkdir -p $(dirname ./build/${variant_name}/png${1}.png)
    mkdir -p $(dirname ./build/${variant_name}/svg${1}.svg)

    echo -e "=> 🔨 Render '${1}' - ${variant_name} variant "

    if test -f "./src/${variant_name}${1}.svg"; then
        src="./src/${variant_name}${1}.svg"
    else
        src="./src/default${1}.svg"
    fi

    scour $src "./build/${variant_name}/svg${1}.svg" \
        --no-line-breaks \
        --strip-xml-prolog \
        --create-groups \
        --enable-id-stripping \
        --strip-xml-space \
        --remove-descriptive-elements \
        --enable-comment-stripping \
        &>/dev/null

    # replace placeholder colors
    sed -i "s/0f0/${accent_color}/g" "./build/${variant_name}/svg${1}.svg"
    sed -i "s/00f/${brightness_color}/g" "./build/${variant_name}/svg${1}.svg"

    # Render PNG
    cairosvg "./build/${variant_name}/svg${1}.svg" -o "./build/${variant_name}/png${1}.png" &>/dev/null
    optipng -o7 "./build/${variant_name}/png${1}.png" &>/dev/null
}
export -f render_icon

function generate_links() {
    echo -e "=> 🌠 Copy and format links.txt in build\n"

    for variant in "${variants[@]}"; do
        variant=( $variant )
        variant_name=${variant[0]}
        
        cp -f "./src/links.txt" "./build/${variant_name}/png/links.txt"
        sed -i 's/.xxx/.png/g' "./build/${variant_name}/png/links.txt"

        cp -f "./src/links.txt" "./build/${variant_name}/svg/links.txt"
        sed -i 's/.xxx/.svg/g' "./build/${variant_name}/svg/links.txt"
    done
}

function generate_zip() {
    rm -Rf "dist"
    mkdir -p -v "dist" &>/dev/null

    for variant in "${variants[@]}"; do
        variant=( $variant )
        variant_name=${variant[0]}

        if [[ $variant_name == "default" ]]; then
            archive_filename="images_yaru"
        else
            archive_filename="images_yaru_${variant_name}"
        fi

        echo "=> 📦 Zip ${variant_name} svg icons"
        cd "build/${variant_name}/svg"
        zip -q -r "${archive_filename}_svg.zip" *

        echo "=> 📦 Zip ${variant_name} png icons"
        cd "../png"
        zip -q -r "${archive_filename}.zip" *

        cd "../../.."

        mv "build/${variant_name}/png/${archive_filename}.zip" "dist/${archive_filename}.zip"
        mv "build/${variant_name}/svg/${archive_filename}_svg.zip" "dist/${archive_filename}_svg.zip"
    done

    echo -e "\n=> 🎉 ZIP generated!\n"
}

function generate_oxt() {
    check_deps "cairosvg" "optipng"

    generate_zip

    mkdir -p -v "oxt/iconsets" &>/dev/null

    for variant in "${variants[@]}"; do
        variant=( $variant )
        variant_name=${variant[0]}
        accent_color=${variant[1]}

        if [[ $variant_name == "default" ]]; then
            accent_color="e95420"
            archive_filename="images_yaru"
            oxt_filename="yaru-theme"
            oxt_title="Yaru icon theme"
            oxt_identifier="org.iconset.Yaru"
        else
            archive_filename="images_yaru_${variant_name}"
            oxt_filename="yaru-${variant_name}-theme"
            oxt_title="Yaru icon theme (${variant_name} variant)"
            oxt_identifier="org.iconset.Yaru-${variant_name}"
        fi

        echo "=> 🎁 Build ${variant_name} OXT"

        #Create temp files
        cp -r "oxt/" "dist/"
        cd "dist"
        cp -f "${archive_filename}.zip" "oxt/iconsets/${archive_filename}.zip"
        cp -f "${archive_filename}_svg.zip" "oxt/iconsets/${archive_filename}_svg.zip"

        # Update metadata
        cd "oxt"
        sed -i "s|%title%|${oxt_title}|g" "description.xml"
        sed -i "s|%identifier%|${oxt_identifier}|g" "description.xml"
        sed -i "s|%update_path%|https://raw.githubusercontent.com/ubuntu/libreoffice-style-yaru-fullcolor/master/updates/${oxt_filename}.update.xml|g" "description.xml"

        # Accented logo
        sed -i "s/0ff/${accent_color}/g" "logo.svg"
        cairosvg "logo.svg" -o "logo.png" &>/dev/null
        optipng -o7 "logo.png" &>/dev/null
        rm "logo.svg"

        # Zip and create OXT
        zip -q -r "${oxt_filename}.oxt" * -x update.xml version.txt
        sed -i "s|%title%|${oxt_title}|g" "description.xml"
        cd ..
        mv "oxt/${oxt_filename}.oxt" "./"
        rm -Rf "oxt"
        cd ..
    done

    echo -e "\n=> 🎉 OXT generated!\n"
}

###################################################
# MAIN 
###################################################

if [[ $_all = 1 ]];
then
    check_deps "parallel"

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

    parallel render_icon ::: "${filenames[@]}" ::: "${variants[@]}"

    generate_links
elif [[ $_watch = 1 ]];
then
    check_deps "parallel" "inotifywait"

    echo -e "=> 🔍 Lets watch file changes (abort with CTRL+C) ...\n"

    while true; do
        filename=$(inotifywait -r -q --event close_write --format %w%f ./src/)

        if [[ $filename == ./src/links.txt ]]; then
            generate_links
        elif [[ $filename == ./src/* ]]; then
            if [[ $filename == *.svg ]];
            then
                for variant_color in "${variants[@]}"; do
                    variant_color=( $variant_color )
                    variant_name=${variant_color[0]}

                    if [[ $filename == ./src/${variant_name}/* ]]; then
                        filename=${filename#"./src/${variant_name}"}
                    fi
                done

                filename=${filename%".svg"}

                parallel render_icon ::: "${filename}" ::: "${variants[@]}"

                echo
            fi
        fi
    done
elif [[ $_links = 1 ]];
then
    generate_links
elif [[ $_zip = 1 ]];
then
    generate_zip
elif [[ $_oxt = 1 ]];
then
    generate_oxt
elif [[ ! -z "$_file" ]]; then
    check_deps "parallel"

    parallel render_icon ::: "${_file}" ::: "${variants[@]}"
else
    echo -e "❌ Error, please provide a valid option\n"
    exit 1
fi
