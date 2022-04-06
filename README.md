# Libreoffice style Yaru

A fullcolor icon pack for Libreoffice of the awesome Yaru theme.

All these icons are based on the [Yaru icon](https://github.com/ubuntu/yaru) theme (derived from the Unity8 Suru icons and [Suru icon](https://snwh.org/suru) theme) and the Breeze icons for Libreoffice.

![Preview of Libreoffice style Yaru](preview/libreoffice-style-yaru.png)

If you want to contribute, please look at [CONTRIBUTING.md](./CONTRIBUTING.md).

## Install

### From extensions.libreoffice.org

Installing from the official Libreoffice extension site is the the best way if you just want to use this icon pack without modification and if you want to have easy updates.
Just download the lastest release here: https://extensions.libreoffice.org/en/extensions/show/1042

Then open the .oxt file with Libreoffice or, open __Tools__ → __Extension Manager__ (or __Ctrl__ + __Alt__ + __E__) then click on __Add__ and browse for local directory where the extension placed.

### From extension

Since Libreoffice 6.0, you can install an icon pack with an extension. To do that, simply clone the repository and generate the extension with the build script at the root of the project:

```bash
git clone https://github.com/ubuntu/libreoffice-style-yaru-fullcolor.git
cd libreoffice-style-yaru-fullcolor
./build.sh -e
```

This will generate a `yaru-theme.oxt` file.
Open it with Libreoffice or, open __Tools__ → __Extension Manager__ (or __Ctrl__ + __Alt__ + __E__) then click on __Add__ and browse for local directory where the extension placed.

### From script

⚠ Installing from script do not work when using a confined version of Libreoffice (like snap packages), in that case you must use the extension.

Because it is faster, install from script will be useful if you want to modify the icons and reinstall the pack many times for testing:

```bash
git clone https://github.com/ubuntu/libreoffice-style-yaru-fullcolor.git
cd libreoffice-style-yaru-fullcolor
./install.sh
```

⚠ Installing from script and extension will duplicate the icon pack into the options, so you should remove one before using the other way.

---

In any case, you need to enable the theme: open the options __Tools__ → __Options__ (or __Alt__ + __F12__) then go to __LibreOffice__ → __View__ → __Icon style__ and select __Yaru__.

## Remove

### From extension

To remove the extension, open __Tools__ → __Extension Manager__ (or __Ctrl__ + __Alt__ + __E__) then select the theme in the list and click on __Remove__. That's it.

### From script

If you want to remove an installation made with the script just execute the remove script at the root of the project:

```bash
./install.sh -u
```

## Copying or Reusing

This project has mixed licencing. You are free to copy, redistribute and/or modify aspects of this work under the terms of each licence accordingly (unless otherwise specified).

All images (any and all source `.svg` files or rendered `.png` files) are licensed under the terms of the [Creative Commons Attribution-ShareAlike 4.0 License](https://creativecommons.org/licenses/by-sa/4.0/).

Included scripts are free software licensed under the terms of the [GNU Lesser General Public License, version 3](https://www.gnu.org/licenses/lgpl-3.0.txt).
