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

###################################################
# CHECKS
###################################################

echo

if ! command -v parallel >/dev/null
then
    echo  -e "=> 🙅 Please install parallel\n"
    exit 1
fi

###################################################
# POPULATE ACCENT COLORS
###################################################

function read_map_file() {
    local line
    local splitedline
    local n=0
    local expected_fields=$2

    while IFS= read -r line; do
        n=$((n+1))
        [[ -z "$line" || "$line" =~ ^# ]] && continue

        read -ra splitedline <<< "$line"
        if (( ${#splitedline[@]} != expected_fields )); then
            echo "Error in \"$1\": $line (line $n)" >&2
            exit 1
        fi
        printf '%s\n' "$line"
    done < $1
}

output=$(read_map_file "src/accents.txt" 2)
mapfile -t accents <<< "$output"

output=$(read_map_file "src/brightness.txt" 3)
mapfile -t brightness <<< "$output"

# Should be an array of:
# variant_name accent_color bg_color txt_color
variants=()

for accent in "${accents[@]}"; do
    accent=( $accent )
    accent_name=${accent[0]}
    accent_color=${accent[1]}

    for bness in "${brightness[@]}"; do
        bness=( $bness )
        brightness_name=${bness[0]}
        bg_color=${bness[1]}
        txt_color=${bness[2]}

        variant_name=''

        if [[ $brightness_name == 'default' ]]; then
            variant_name=$accent_name
        elif [[ $accent_name == 'default' && $brightness_name != 'default' ]]; then
            variant_name=$brightness_name
        else
            variant_name="${accent_name}_${brightness_name}"
        fi

        variants+=( "$variant_name $accent_color $bg_color $txt_color" )
    done
done

###################################################
# FUNCTIONS
###################################################

errors=0

function check_links() {
    workingfolder=$1
    defaultlinksfile="${1}/links.txt"
    linksfile="${2:-$defaultlinksfile}"
    n=1
    linkedicons=()
    targeticons=()

    while read line; do
        if [ "$line" = "" ] || [[ "$line" =~ ^#.*  ]]
        then
            continue
        fi

        IFS=' '
        read -ra splitedline <<< "$line"
        if [[ ${#splitedline[@]} > 2 ]] || [[ ${#splitedline[@]} < 2 ]]; then
            echo "Error line $n: Malformed line '$line'"
            let errors+=1
        else
            linkedicons+=(${splitedline[0]})
            targeticons+=(${splitedline[1]})
        fi

        let n+=1
    done < $linksfile

    n=1

    for i in "${targeticons[@]}"
    do
        if [[ " ${linkedicons[@]} " =~ " ${i} " ]]; then

            linkediconindex=
            for j in "${!linkedicons[@]}"; do
                if [[ "${linkedicons[$j]}" = "${i}" ]]; then
                   linkediconindex=$j
                   break
               fi
            done

            echo "Error line $n: Link ${linkedicons[n-1]} -> $i -> ${targeticons[linkediconindex]}"

            let errors+=1
        fi
        let n+=1
    done

    n=1

    for i in "${targeticons[@]}"
    do
        if [ ! -f "./${workingfolder}/${i/.xxx/.svg}" ]; then

            echo "Error line $n: target file ${workingfolder}/${i/.xxx/.svg} not found"

            let errors+=1
        fi
        let n+=1
    done
}
export -f check_links

###################################################
# MAIN 
###################################################

echo -e "=> ⏳ Checking links.txt source file - please wait\n"

check_links "src/default" "src/links.txt"

if [[ ${errors} > 0 ]]; then
    echo -e "\n=> $errors error(s) found\n"
    exit 1
else
    for variant in "${variants[@]}"; do
        resources=(
            "build/${variant}/svg"
            "build/${variant}/png"
        )
    done

    echo -e "=> ⏳ Checking links.txt built files - please wait"

    parallel check_links ::: "${resources[@]}"

    if [[ ${errors} > 0 ]]; then
        echo -e "\n=> Errors found into /build links files - please run ${bold}./build.sh -l${normal} and/or ${bold}./build.sh -a${normal} to fix them\n"
        exit 1
    else
        echo -e "\n=> 🎉 0 error found\n"
        exit 0
    fi
fi
