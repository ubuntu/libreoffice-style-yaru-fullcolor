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
# POPULATE VARIANTS COLORS
###################################################

source "$(dirname -- "${BASH_SOURCE[0]}")/scripts/common.sh"

load_variants || exit 1

###################################################
# FUNCTIONS
###################################################

errors=0

function check_links() {
    local workingfolder=$1
    local linksfile=${2:-$1/links.txt}
    local line target path index
    local n=0
    local -a fields linkedicons targeticons line_numbers
    local -A link_targets checked_targets
    errors=0

    if [[ ! -r $linksfile ]]; then
        printf 'Error: cannot read "%s"\n' "$linksfile" >&2
        errors=1
        return 1
    fi

    while IFS= read -r line || [[ -n $line ]]; do
        (( n+=1 ))
        [[ -z ${line//[[:space:]]/} || $line =~ ^[[:space:]]*# ]] && continue

        read -r -a fields <<< "$line"
        if (( ${#fields[@]} != 2 )); then
            printf 'Error in "%s" line %d: Malformed line "%s"\n' "$linksfile" "$n" "$line"
            (( errors+=1 ))
            continue
        fi

        linkedicons+=("${fields[0]}")
        targeticons+=("${fields[1]}")
        line_numbers+=("$n")
        # Preserve the first destination when a link name occurs more than once.
        if [[ -z ${link_targets[${fields[0]}]+x} ]]; then
            link_targets[${fields[0]}]=${fields[1]}
        fi
    done < "$linksfile"

    for index in "${!targeticons[@]}"; do
        target=${targeticons[index]}
        n=${line_numbers[index]}
        # Associative lookups avoid scanning every link for every target.
        if [[ -n ${link_targets[$target]+x} ]]; then
            printf 'Error in "%s" line %d: Link %s -> %s -> %s\n' \
                "$linksfile" "$n" "${linkedicons[index]}" "$target" "${link_targets[$target]}"
            (( errors+=1 ))
        fi

        # Many links share a target; stat each existing file only once per theme.
        if [[ -n ${checked_targets[$target]+x} ]]; then
            continue
        fi
        path=$workingfolder/${target/.xxx/.svg}
        if [[ -f $path ]]; then
            checked_targets[$target]=1
        else
            printf 'Error in "%s" line %d: target file %s not found\n' "$linksfile" "$n" "$path"
            (( errors+=1 ))
        fi
    done

    (( errors == 0 ))
}
export -f check_links

###################################################
# MAIN 
###################################################

echo -e "=> ⏳ Checking links.txt source file - please wait\n"

if ! check_links "src/default" "src/links.txt"; then
    echo -e "\n=> $errors error(s) found\n"
    exit 1
else
    for variant in "${variants[@]}"; do
        read -r variant_name _ <<< "$variant"
        resources+=(
            "build/${variant_name}/svg"
            "build/${variant_name}/png"
        )
    done

    echo -e "=> ⏳ Checking links.txt built files - please wait"

    if ! parallel check_links ::: "${resources[@]}"; then
        echo -e "\n=> Errors found into /build links files - please run ${bold}./build.sh -l${normal} and/or ${bold}./build.sh -a${normal} to fix them\n"
        exit 1
    else
        echo -e "\n=> 🎉 0 error found\n"
        exit 0
    fi
fi
