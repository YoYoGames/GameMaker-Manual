# GameMaker Manual

Welcome to the source of the GameMaker manual. [View other languages here](https://github.com/topics/gm-manual).

This manual is made using Adobe RoboHelp 2022.0.346. It is recommended to use RoboHelp to modify the manual.

You can open the project file in RoboHelp, contained in [/Manual/GMS2_Manual.rhpj](/Manual/GMS2_Manual.rhpj).

The second recommended way is to edit the HTML files directly, which are placed within [/Manual/contents](/Manual/contents).

⚠️ If you use a program that modifies the HTML file beyond the content changes you wanted to make, your PRs will be rejected.

### Please be careful when editing the manual.

:hand: Be aware of the writing and formatting styles used within the existing text, and make sure your additions/changes are consistent with them.

:wrench: For making your changes, it is recommended that you make a fork, clone it and edit locally where you can test your HTML in your browser.

:white_check_mark: Once you are done, push your changes to your fork on GitHub and create a pull request.

### Important

1. Use of this manual source is not intended for end users (e.g. downloading this repository and reading the HTML files for use with GameMaker). This is only a source from which the final manual is built, which is available on [the manual website](https://manual.gamemaker.io) and for download through the IDE (when using the offline manual option in Preferences -> General -> Help).

2. Do not make changes to `<span data-keyref>` contents, these are RoboHelp variables and contents of these span tags should not be manually edited in the HTML files. The correct contents are inserted by RoboHelp when the manual is built (taken from the Manual/variable/Default.var file).

3. If you need to change such an item, refer to the Manual/variable/Default.var file and modify the contents of a variable there (like fixing a link for a data type).
