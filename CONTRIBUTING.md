# Contributing to Libreoffice Yaru

⚠ These are the instructions for contributing and modifying the Libreoffice Yaru icon theme. If you're not a developer, follow the install instructions in the [README.md](./README.md).

You need to install these packages to working on the icons:

```bash
sudo apt install inkscape optipng git
```

⚠ Svgs should be edited only with Inkscape and rendered only with the given script.

## Fork, clone and install

Firstly, on our GitHub page (where you are probably reading this), _fork_ the Libreoffice Yaru repository.
Then clone your copy locally and install it:

```bash
git clone https://github.com/yourusername/libreoffice-style-yaru-fullcolor.git
cd libreoffice-style-yaru-fullcolor
./install.sh
```

⚠ Don't forget to enable the theme: in Libreoffice open the options __Tools__ → __Options__ (or __Alt__ + __F12__) then go to __LibreOffice__ → __View__ → __Icon style__ and select __Yaru__.

You can now working on the icons!

## Create or edit an icon

Open an icon with Inkscape from the `src` folder then do your changes and save.
Now at the root of the project folder, execute the `build.sh` script like this (for an icon located into ./src/cmd/lc_bold.svg):

```bash
./build.sh /cmd/lc_bold
```

⚠ Do not provide the file extension and don't forget to add the `/` before the file path.

This will generate and optimize the corresponding PNG into the `build` folder, and also regenerate the ZIP and the OXT of the icon pack.

Then use the install script and open Libreoffice (you should close all instances before for reloading the icons) to test your changes:

```bash
./install.sh
```

**Watch icons change:**

If you need to edit a lot of icons, you can run the build script in watch mode:

```bash
./build.sh -w
```
Then just edit and save an icon, the build script will automatically build it!

## Make a Pull Request (PR)

Create a feature branch for development:

```bash
git checkout master
git checkout -b branch-name
```

The branch name should summarize the desired changes; also if it is a fix for an issue numbered 1234, a good name could be something like `issue1234/fix-for-something`

Once you are done with your work, use `git status` to see the list of changed (and eventually new) files and stage them with `git add` and commit your work with `git commit`:

```
git status
On branch issue1234/fix-for-something
Changes not staged for commit:
  (use "git add <file>..." to update what will be committed)
  (use "git checkout -- <file>..." to discard changes in working directory)

        modified:   icon.svg
...
```

```bash
git add icon.svg
```

```bash
git commit
```

Now think about a good commit message. The expected format is like the following:

```
short explanation of the commit

A more detailed explanation, possibly explaining the current state, why a change is needed and how you implemented the change. Try to find a good compromise between too short and too long.

If it is a fix for an issue numbered 1234, inform GitHub system so that it can close it automatically when the PR is merged, like this:

closes #1234
```

Finally, make a Pull Request (PR) from branch-name:

```bash
git push --set-upstream origin add-git-workflow
```

Open Libreoffice Yaru GitHub repository page, a link to __"Create your Pull request"__ should appear on the main page
