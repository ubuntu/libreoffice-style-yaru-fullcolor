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

## Update coverage report.
##
## usage: update-coverage.sh [options]
## options:
##      -u, --upstream  Update upstream coverage before generating coverage diff.

# Parsing flags and arguments
while getopts 'hu' OPT; do
    case "$OPT" in
        h) sed -ne 's/^## \(.*\)/\1/p' "$0"
           exit 1 ;;
        u) _upstream=1 ;;
        \?) print_illegal "$@" >&2;
            echo "---"
            sed -ne 's/^## \(.*\)/\1/p' "$0"
            exit 1
            ;;
    esac
done
# CLInt GENERATED_CODE: end

#####################
# Project icons
#####################

echo "Updating project icons coverage"

filenames=()

# List SVG sources
while read -d $'\0' filename
do
    filename=${filename#"./src/default/"}
    filename=${filename%".svg"}
    filenames+=("$filename")
done < <(find "./src/default" -name "*.svg" -print0)

# Include links
n=1
while IFS= read -r line; do
    if [[ -z ${line//[[:space:]]/} || $line =~ ^[[:space:]]*# ]]; then
        ((n++))
        continue
    fi

    read -r -a split_line <<< "$line"
    if (( ${#split_line[@]} != 2 )); then
        printf "Error line %d: malformed line '%s'\n" "$n" "$line"
    else
        filenames+=(${split_line[0]%".xxx"})
    fi

    ((n++))
done < "./src/links.txt"

# Sort
readarray -t filenames < <(
    printf '%s\n' "${filenames[@]}" | sort
)

# Export to file
printf "%s\n" "${filenames[@]}" > coverage/coverage.txt

#####################
# Upstream icons
#####################

echo "Updating upstream icons coverage"

upstream_filenames=()

if [[ $_upstream = 1 ]];
then
    # List PNG sources
    mapfile -t upstream_filenames < <(
    gh api \
        "repos/LibreOffice/core/git/trees/master?recursive=1" \
        --jq ".tree[]
            | select(.type == \"blob\")
            | select(.path | startswith(\"icon-themes/colibre/\"))
            | select(.path | ascii_downcase | endswith(\".png\"))
            | .path"
    )

    # Normalize
    for i in "${!upstream_filenames[@]}"
    do
        filename=${upstream_filenames[i]}
        filename=${filename#"icon-themes/colibre/"}
        filename=${filename%".png"}
        upstream_filenames[i]=$filename
    done

    # Include links
    n=1
    errors=0
    upstream_links_url="https://raw.githubusercontent.com/LibreOffice/core/refs/heads/master/icon-themes/colibre/links.txt"
    if ! upstream_links=$(
        curl --fail --silent --show-error --location "$upstream_links_url"
    ); then
        printf 'Error: failed to download %s\n' "$upstream_links_url" >&2
        exit 1
    fi
    while IFS= read -r line; do
        # Ignore empty lines and comments, including leading whitespace
        if [[ -z ${line//[[:space:]]/} || $line =~ ^[[:space:]]*# ]]; then
            ((n++))
            continue
        fi

        # Split the line on whitespace
        read -r -a split_line <<< "$line"

        if (( ${#split_line[@]} != 2 )); then
            printf "Error line %d: malformed line '%s'\n" "$n" "$line"
            ((errors++))
        else
            upstream_filenames+=("${split_line[0]%.png}")
        fi

        ((n++))
    done <<< "$upstream_links"

    # Sort
    readarray -t upstream_filenames < <(
        printf '%s\n' "${upstream_filenames[@]}" | sort
    )

    # Export to file
    printf '%s\n' "${upstream_filenames[@]}" > coverage/upstream-coverage.txt
fi

#################
# Generate diff
#################

echo "Updating coverage diff"

git diff --no-index --unified=0 coverage/coverage.txt coverage/upstream-coverage.txt  | grep -E '^[+-]' | grep -vE '^\+\+\+|^---' > coverage/coverage.diff
