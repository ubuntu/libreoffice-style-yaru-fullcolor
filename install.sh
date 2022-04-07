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
		sudo rm -f -v "$dir/images_yaru.zip"
		sudo rm -f -v "$dir/images_yaru_svg.zip"
		sudo rm -f -v "$dir/images_yaru_mate.zip"
		sudo rm -f -v "$dir/images_yaru_mate_svg.zip"
	done
}

function install() {
	sudo mkdir -p -v "/usr/share/libreoffice/share/config"
	sudo cp -v "dist/images_yaru.zip" "/usr/share/libreoffice/share/config/images_yaru.zip"
	sudo cp -v "dist/images_yaru_svg.zip" "/usr/share/libreoffice/share/config/images_yaru_svg.zip"
	sudo cp -v "dist/images_yaru_mate.zip" "/usr/share/libreoffice/share/config/images_yaru_mate.zip"
	sudo cp -v "dist/images_yaru_mate_svg.zip" "/usr/share/libreoffice/share/config/images_yaru_mate_svg.zip"

	for dir in \
		/usr/lib64/libreoffice/share/config \
		/usr/lib/libreoffice/share/config \
		/usr/local/lib/libreoffice/share/config \
		/opt/libreoffice*/share/config; do
			[ -d "$dir" ] || continue
			sudo ln -sf -v "/usr/share/libreoffice/share/config/images_yaru.zip" "$dir"
			sudo ln -sf -v "/usr/share/libreoffice/share/config/images_yaru_svg.zip" "$dir"
			sudo ln -sf -v "/usr/share/libreoffice/share/config/images_yaru_mate.zip" "$dir"
			sudo ln -sf -v "/usr/share/libreoffice/share/config/images_yaru_mate_svg.zip" "$dir"
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

	echo -e "\n=> 🔥 Removing old install\n"

	uninstall

	echo -e "\n=> 📥 Installing Libreoffice style Yaru\n"

	install

	echo -e "\n=> 🎉 Finish (don't forget to restart Libreoffice)!\n"
fi
