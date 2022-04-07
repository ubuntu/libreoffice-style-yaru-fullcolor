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
    resources=(
        "build/default/svg"
        "build/default/png"
        "build/mate/svg"
        "build/mate/png"
    )

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
