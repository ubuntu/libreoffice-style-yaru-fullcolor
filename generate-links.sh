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

echo -e "\n=> 🌠 Copy links.txt\n"

cp -f "./src/links.txt" "./build/png/links.txt"
sed -i 's/.xxx/.png/g' "./build/png/links.txt"

cp -f "./src/links.txt" "./build/svg/links.txt"
sed -i 's/.xxx/.svg/g' "./build/svg/links.txt"

cp -f "./build/png/links.txt" "./build/mate/png/links.txt"
cp -f "./build/svg/links.txt" "./build/mate/svg/links.txt"

echo -e "\n=> 🎉 Finish\n"
