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

## Install script
##
## usage: ./install.sh [options]
##
## options:
##      -u, --uninstall   Uninstall this icon pack [default: 0]
##      -v, --variant <name> Only install or uninstall this variant; repeat to select multiple variants

# CLInt GENERATED_CODE: start
# Default values
_uninstall=0
_requested_variants=()

# Converting long-options into short ones
for arg in "$@"; do
  shift
  case "$arg" in
"--uninstall") set -- "$@" "-u";;
"--variant") set -- "$@" "-v";;
  *) set -- "$@" "$arg"
  esac
done

function print_illegal() {
    echo Unexpected flag in command line \"$@\"
}

# Parsing flags and arguments
while getopts 'huv:' OPT; do
    case $OPT in
        h) sed -ne 's/^## \(.*\)/\1/p' $0
           exit 1 ;;
        u) _uninstall=1 ;;
        v) _requested_variants+=( "$OPTARG" ) ;;
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

source "$(dirname -- "${BASH_SOURCE[0]}")/scripts/common.sh"

load_variants || exit 1
filter_variants "${_requested_variants[@]}" || exit 1

###################################################
# FUNCTIONS
###################################################

function uninstall() {
	for dir in \
	  /usr/share/libreoffice/share/config \
	  /usr/lib/libreoffice/share/config \
	  /usr/lib64/libreoffice/share/config \
	  /usr/local/lib/libreoffice/share/config \
	  /opt/libreoffice*/share/config; do
	  	[ -d "$dir" ] || continue
		for variant in "${variants[@]}"; do
			read -r variant_name _ <<< "$variant"
			theme_name=$(get_theme_name "$variant_name")

			sudo rm -f -v "$dir/${theme_name}.zip"
			sudo rm -f -v "$dir/${theme_name}_svg.zip"
		done
	done
}

function install() {
	sudo mkdir -p -v "/usr/share/libreoffice/share/config"

	for variant in "${variants[@]}"; do
		read -r variant_name _ <<< "$variant"
		theme_name=$(get_theme_name "$variant_name")

		sudo cp -v "dist/${theme_name}.zip" "/usr/share/libreoffice/share/config/${theme_name}.zip"
		sudo cp -v "dist/${theme_name}_svg.zip" "/usr/share/libreoffice/share/config/${theme_name}_svg.zip"
		sudo chmod 644 "/usr/share/libreoffice/share/config/${theme_name}.zip"
		sudo chmod 644 "/usr/share/libreoffice/share/config/${theme_name}_svg.zip"

		for dir in \
		/usr/lib64/libreoffice/share/config \
		/usr/lib/libreoffice/share/config \
		/usr/local/lib/libreoffice/share/config \
		/opt/libreoffice*/share/config; do
			[ -d "$dir" ] || continue
			sudo ln -sf -v "/usr/share/libreoffice/share/config/${theme_name}.zip" "$dir"
			sudo ln -sf -v "/usr/share/libreoffice/share/config/${theme_name}_svg.zip" "$dir"
		done
	done
}

function clear_cache() {
    for dir in \
    ~/.config/libreoffice/4/cache \
    ~/.config/libreoffice/3/cache \
    ~/.libreoffice/3/cache; do
        [ -d "$dir" ] || continue
        sudo rm -f -r "$dir"
    done
}

###################################################
# MAIN 
###################################################

if [[ $_uninstall = 1 ]];
then
	echo -e "\n=> 🔥 Removing Libreoffice style Yaru\n"

	uninstall

	echo -e "\n=> 🎉 Finish\n"
else
	build_args=( --zip )
	if (( ${#_requested_variants[@]} > 0 )); then
		for variant in "${variants[@]}"; do
			read -r variant_name _ <<< "$variant"
			build_args+=( --variant "$variant_name" )
		done
	fi
	./build.sh "${build_args[@]}"

	if [[ $? -ne 0 ]]; then
	    exit 1
	fi

	echo -e "\n=> 🔥 Removing old install\n"

	uninstall

	echo -e "\n=> 📥 Installing Libreoffice style Yaru\n"

	install

	echo -e "\n=> 🧹 Clear icon cache\n"

	clear_cache

	echo -e "\n=> 🎉 Finish (don't forget to restart Libreoffice)!\n"
fi
