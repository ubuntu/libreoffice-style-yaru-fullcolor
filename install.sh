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

# CLInt GENERATED_CODE: start
# Default values
_uninstall=0

# Converting long-options into short ones
for arg in "$@"; do
  shift
  case "$arg" in
"--uninstall") set -- "$@" "-u";;
  *) set -- "$@" "$arg"
  esac
done

function print_illegal() {
    echo Unexpected flag in command line \"$@\"
}

# Parsing flags and arguments
while getopts 'hu' OPT; do
    case $OPT in
        h) sed -ne 's/^## \(.*\)/\1/p' $0
           exit 1 ;;
        u) _uninstall=1 ;;
        \?) print_illegal $@ >&2;
            echo "---"
            sed -ne 's/^## \(.*\)/\1/p' $0
            exit 1
            ;;
    esac
done
# CLInt GENERATED_CODE: end

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
        accents+=( ${splitedline[0]} )
    fi
done < "src/accents.txt"

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
		for accent in "${accents[@]}"; do
			if [[ $accent == "default" ]]; then
				theme_name="yaru"
			else
				theme_name="yaru_${accent}"
			fi

			sudo rm -f -v "$dir/images_${theme_name}.zip"
			sudo rm -f -v "$dir/images_${theme_name}_svg.zip"
		done
	done
}

function install() {
	sudo mkdir -p -v "/usr/share/libreoffice/share/config"

	for accent in "${accents[@]}"; do
		if [[ $accent == "default" ]]; then
			theme_name="yaru"
		else
			theme_name="yaru_${accent}"
		fi

		sudo cp -v "dist/images_${theme_name}.zip" "/usr/share/libreoffice/share/config/images_${theme_name}.zip"
		sudo cp -v "dist/images_${theme_name}_svg.zip" "/usr/share/libreoffice/share/config/images_${theme_name}_svg.zip"

		for dir in \
		/usr/lib64/libreoffice/share/config \
		/usr/lib/libreoffice/share/config \
		/usr/local/lib/libreoffice/share/config \
		/opt/libreoffice*/share/config; do
			[ -d "$dir" ] || continue
			sudo ln -sf -v "/usr/share/libreoffice/share/config/images_${theme_name}.zip" "$dir"
			sudo ln -sf -v "/usr/share/libreoffice/share/config/images_${theme_name}_svg.zip" "$dir"
		done
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
	./build.sh --oxt

	if [[ $? -ne 0 ]]; then
	    exit 1
	fi

	echo -e "\n=> 🔥 Removing old install\n"

	uninstall

	echo -e "\n=> 📥 Installing Libreoffice style Yaru\n"

	install

	echo -e "\n=> 🎉 Finish (don't forget to restart Libreoffice)!\n"
fi
