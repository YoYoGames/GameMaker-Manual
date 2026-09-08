### Python script to generate copy-pasteable HTML tables from JSON file
###
### Provide the full directory path to the .json file as the command line argument.
### The output HTML file will also be placed there.
### For example: CMD > python GenerateKeyboardShortcutTableFromJson.py "C:/Users/Dev/GitHub/GameMaker-Manual/Manual/" -env prod
###
### You can provide a few optional arguments: 
### 
### -name_as_desc: Add this to write the hotkey's name as the description.
### -env: Provide this, followed by the environment in which you want to look for the JSON file
###       (one of: "dev", "lts", "beta", "prod"), or a full path to a GameMaker installation.
###       Named environments are located through the Windows uninstall registry, so installs on
###       a non-default drive or with a non-default folder name are found too. Pass a full path
###       to skip that lookup.
###       Note: the named environments only work on Windows!
###

import sys
import os
import json
import re
from collections import OrderedDict

# Unique modifier keys
mods = set()

# Subdirectories of a GameMaker installation that hold the hotkey JSON files
hotkey_dirs = [
    "Plugins/GlobalHotkeys",
    "Plugins/TextEditorHotkeys",
    "Plugins/TextEditor2Hotkeys",
    "Hotkeys"
]

def find_hotkey_files(dir):
    """Find all hotkey JSON files in the subdirectories where we expect to find them"""

    filenames = []
    
    for fdir in hotkey_dirs:
        fulldir = dir + "/" + fdir
        for _, _, names in os.walk(fulldir):
            filenames.extend([fulldir + "/" + f for f in names if f.endswith(".json")])
    
    return filenames

def get_combo_string(combo, replace_in_names=[]):
    global mods
    if not combo:
        combo_string = ""
    else:
        modifier = [key for key in combo['Modifier'].split(", ") if key != "None"]
        mods.update(modifier)
        if type(combo['Keys']) is list:
            # This is a hotkey chord
            mods = " + ".join([*modifier])
            combo_string = " => ".join([mods + " + " + key for key in combo['Keys']])
        else:
            # This is a regular hotkey
            combo_string = " + ".join([*modifier, combo['Keys']])
        
        if replace_in_names:
            for item in replace_in_names:
                combo_string = combo_string.replace(item[0], item[1])
    return combo_string

# Default install directory names, which double as the names the installers register themselves under
install_dirs = {
    "dev": "GameMaker-Dev",
    "lts": "GameMaker-LTS",
    "beta": "GameMaker-Beta",
    "prod": "GameMaker"
}

def read_reg_value(key, name):
    """Read a single string value from an open registry key, or None if it isn't there"""
    import winreg
    try:
        value, _ = winreg.QueryValueEx(key, name)
    except OSError:
        return None
    return value if isinstance(value, str) and value else None

def find_install_dir_in_registry(display_name):
    """Find a GameMaker installation through the Windows uninstall registry keys"""

    try:
        import winreg
    except ImportError:
        return None     # not running on Windows

    uninstall_key = "SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Uninstall"
    roots = [
        (winreg.HKEY_LOCAL_MACHINE, uninstall_key),
        (winreg.HKEY_LOCAL_MACHINE, "SOFTWARE\\WOW6432Node\\" + uninstall_key[len("SOFTWARE\\"):]),
        (winreg.HKEY_CURRENT_USER, uninstall_key)
    ]

    for hive, subkey in roots:
        try:
            root = winreg.OpenKey(hive, subkey)
        except OSError:
            continue

        with root:
            for i in range(winreg.QueryInfoKey(root)[0]):
                try:
                    with winreg.OpenKey(root, winreg.EnumKey(root, i)) as entry:
                        # Match exactly, so "GameMaker" doesn't pick up "GameMaker-Beta"
                        if read_reg_value(entry, "DisplayName") != display_name:
                            continue

                        # Prefer InstallLocation, but the GameMaker installers leave it empty,
                        # so fall back to the directory the uninstaller or the icon sits in
                        location = read_reg_value(entry, "InstallLocation")
                        if not location:
                            for value_name in ["UninstallString", "DisplayIcon"]:
                                path = read_reg_value(entry, value_name)
                                if not path:
                                    continue
                                path = path.strip('"')
                                # DisplayIcon may carry a trailing icon index, e.g. "app.exe,0"
                                if value_name == "DisplayIcon" and "," in path:
                                    path = path.rsplit(",", 1)[0]
                                location = os.path.dirname(path)
                                break

                        if location and os.path.isdir(location):
                            return location
                except OSError:
                    continue    # unreadable entry, just move on

    return None

def resolve_in_dir(env, out_dir):
    """Work out which directory to read the hotkey JSON files from"""

    # A full path can be given instead of an environment name, to override the registry lookup
    if os.path.isdir(env):
        return env

    if env not in install_dirs:
        print("ERROR - Unknown environment '{0}'. Expected one of: {1}, or a full directory path. Exiting..."
              .format(env, ", ".join(install_dirs)))
        exit()

    name = install_dirs[env]

    # Ask the registry where this version lives, then try the default install directory
    in_dir = find_install_dir_in_registry(name)
    if not in_dir:
        default_dir = os.environ.get("ProgramFiles", "") + "/" + name
        in_dir = default_dir if os.path.isdir(default_dir) else None

    if not in_dir:
        print("WARNING - No '{0}' installation found, reading from the output directory instead.".format(name))
        return out_dir

    if not any(os.path.isdir(in_dir + "/" + d) for d in hotkey_dirs):
        print("WARNING - '{0}' holds no hotkey directories, reading from the output directory instead.".format(in_dir))
        return out_dir

    return in_dir

# Handle parameters received from command line
if len(sys.argv) == 1:
    print("ERROR - The input/output directory should be provided. Exiting...")
    exit()
else:
    out_dir = sys.argv[1]
    in_dir = out_dir

# Whether to use the shortcut's name as the description
name_as_desc = "-name_as_desc" in sys.argv

# Use an existing GM installation to get the JSON files, if provided
env = "out_dir"
if "-env" in sys.argv:
    ind = sys.argv.index("-env")
    if ind + 1 >= len(sys.argv):
        print("ERROR - -env should be followed by an environment name or a directory path. Exiting...")
        exit()
    env = sys.argv[ind+1]
    in_dir = resolve_in_dir(env, out_dir)

# Check if directories exist
if not os.path.isdir(in_dir) or not os.path.isdir(out_dir):
    print("ERROR - One or more directories don't exist. Exiting...")
    exit()

# Find all the hotkey JSON files in the known subdirectories
fpaths = find_hotkey_files(in_dir)

if not fpaths:
    print("ERROR - No hotkey JSON files found under '{0}'. Nothing written. Exiting...".format(in_dir))
    exit()

# Data structures
input = []                              # input from file
shortcuts = dict()                      # maps shortcut name => shortcut data
shortcuts_per_location = OrderedDict()  # stores shortcuts under locations

# Get shortcuts from all files
for fpath in fpaths:
    with open(fpath, 'r', encoding="utf-8") as f:
        # Load all the data
        input = json.load(f)              # risk of errors if trailing commas are present

        # Add items under their respective locations (i.e. "group" per location)
        for shortcut in input['Hotkeys']:
            # Get unique name
            name = shortcut['Name']

            # Nothing to do for unlisted shortcuts?
            #if 'IsUnlisted' in shortcut:
            if 'IsListed' in shortcut and shortcut['IsListed'] == False:
                continue

            # Get this shortcut's combo(s)
            cbo = shortcut['Combo']
            combos = [cbo] if type(cbo) is not list else cbo
            combo_strings = [get_combo_string(combo) for combo in combos]

            # Store shortcut data (name as the key)
            shortcuts[name] = {
                        "name": name,
                        "description": shortcut['Description'] if ('Description' in shortcut) else "",
                        "win_combo": combo_strings,
                        "mac_combo": combo_strings
                        # "Localisation": combo['Localisation']
            }

            # Store platform overrides, if there are any
            if 'PlatformOverrides' in shortcut and shortcut['PlatformOverrides']:
                for override in shortcut['PlatformOverrides']:
                    if override['Platform'] != 'MacOs':
                        continue

                    # Get this shortcut's Mac combo(s)
                    cbo = override['Combo']
                    if not cbo:
                        shortcuts[name]['mac_combo'] = []    # "empty" override
                    else:
                        combos = [cbo] if type(cbo) is not list else cbo
                        combo_strings = [get_combo_string(combo, replace_in_names=[("Windows", "Command")]) for combo in combos]

                        # Assign to final output
                        shortcuts[name]['mac_combo'] = combo_strings

            # Store name of shortcut under all its locations
            loc = input['Source']
            locations = [loc] if (type(loc) == str) else loc

            for location in locations:
                # Make sure a list exists under the key before writing to it
                if location not in shortcuts_per_location:
                    shortcuts_per_location[location] = OrderedDict()
                
                # Add the shortcut
                shortcuts_per_location[location][name] = name


# Generate HTML
html = ""
for location in shortcuts_per_location:
    html += "<h2>{0}</h2>".format(location)
    html += "<table>\n<tr><th>Windows Key Binding</th><th>macOS Key Binding</th><th>Scope</th><th>Description</th></tr>"
    
    for name in shortcuts_per_location[location].keys():
        sc = shortcuts[name]
        desc = name if name_as_desc else sc['description']
        html += "<tr>"
        # html += "<td>" + name + "</td>"
        # A shortcut with no combo at all, or one explicitly cleared per platform, is unbound
        html += "<td>" + ("<br />".join(sc['win_combo']) or "Unbound") + "</td>"
        html += "<td>" + ("<br />".join(sc['mac_combo']) or "Unbound") + "</td>"
        html += "<td>" + location + "</td>"
        html += "<td>" + desc + "</td>"
        html += "</tr>"

    html += "</table>"

# Write to file
fpath_out = out_dir + "/" + "shortcuts.htm"
with open(fpath_out, 'w') as f:
    f.write(html)

# Report what was read and where it went
print("Read {0} hotkey file(s) of environment '{1}' from:".format(len(fpaths), env))
print(in_dir)
print("Shortcuts written to file:")
print(fpath_out)
