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

function check-links() {
    linksfile=$1
    verbose=$2
    n=1
    errors=0
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

    return $errors
}

bold=$(tput bold)
normal=$(tput sgr0)

echo -e "\n=> ⏳ Checking src/links.txt - please wait"

check-links "src/links.txt"

if [[ $? > 0 ]]; then
    echo -e "\n=> $errors error(s) found\n"
    exit 1
else
    echo -e "\n=> ⏳ Checking build/***/links.txt - please wait"

    if [[ $(check-links 'build/svg/links.txt') > 0 ]] || [[ $(check-links 'build/png/links.txt') > 0 ]]; then
        echo -e "\n=> Errors errors found into /build links files - please run ${bold}./generate-links.sh${normal} to regenerate them\n"
        exit 1
    else
        echo -e "\n=> 🎉 0 error found\n"
        exit 0
    fi
fi
