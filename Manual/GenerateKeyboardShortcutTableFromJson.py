### Python script to generate copy-pasteable HTML tables from JSON file
###
### Provide the full directory path to the .json file as the command line argument.
### The output HTML file will also be placed there.
### For example: CMD > python GenerateKeyboardShortcutTableFromJson.py "C:/Users/Dev/Documents/GitHub/GameMaker-Manual/Manual/" -name_as_desc -env beta
###
### You can provide a few optional arguments: 
### 
### -name_as_desc: Add this to write the hotkey's name as the description.
### -env: Provide this, followed by the environment in which you want to look for the JSON file
###       (one of: "dev", "lts", "beta", "prod")
###       Note: only works on Windows!
### -update_rh_vars: Add this to update the RoboHelp variables
###                  A RH variable is written (or updated if exists) for every Win/Mac shortcut
###                  For example: Hotkey_Create_Asset_Win, Hotkey_Create_Asset_Mac
###

import sys
import os
import json
import re
from collections import OrderedDict

# Write to RoboHelp variables
import xml.etree.ElementTree as ET

# Unique modifier keys
mods = set()

# Utility functions
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

# Default names
fname_hotkeys = "default_hotkeys.json"

install_dirs = {
    "dev": "GameMaker-Dev",
    "lts": "GameMaker-LTS",
    "beta": "GameMaker-Beta",
    "prod": "GameMaker"
}

# Handle parameters received from command line
if len(sys.argv) == 1:
    print("ERROR - The input/output directory should be provided. Exiting...")
    exit()
else:
    out_dir = sys.argv[1]
    in_dir = out_dir

# Whether to use the shortcut's name as the description
name_as_desc = "-name_as_desc" in sys.argv

# Whether to create new and/or update existing RH hotkey variables
write_update_rh_vars = "-update_rh_vars" in sys.argv

# Use an existing GM installation to get the JSON files, if provided
env = "out_dir"
if "-env" in sys.argv:
    ind = sys.argv.index("-env")
    env = sys.argv[ind+1]
    in_dir = os.environ['ProgramFiles'] + os.sep + install_dirs[env]
    if not os.path.isdir(in_dir):
        # Revert to out_dir if there's no such directory
        in_dir = out_dir

# Check if directories exist
if not os.path.isdir(in_dir) or not os.path.isdir(out_dir):
    print("ERROR - One or more directories don't exist. Exiting...")
    exit()

# Check if files exist
fpath_win = in_dir + os.sep + fname_hotkeys
if not os.path.isfile(fpath_win):
    print("ERROR - Shortcuts file doesn't exist. Exiting...")
    exit()

# Data structures
input = []                              # input from file
shortcuts = dict()                      # maps shortcut name => shortcut data
shortcuts_per_location = OrderedDict()  # stores shortcuts under locations

# Read the defaults file
with open(fpath_win, 'r', encoding="utf-8") as f:
    # Load all the data
    input = json.load(f)              # risk of errors if trailing commas are present

    # Add items under their respective locations (i.e. "group" per location)
    for shortcut in input:
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
                    "mac_combo": []
                    # "Localisation": combo['Localisation']
        }

        # Store platform overrides, if there are any
        if 'PlatformOverrides' in shortcut and shortcut['PlatformOverrides']:
            for override in shortcut['PlatformOverrides']:
                if override['Platform'] != 'MacOs':
                    continue

                # Get this shortcut's Mac combo(s)
                cbo = override['Combo']
                combos = [cbo] if type(cbo) is not list else cbo
                combo_strings = [get_combo_string(combo, replace_in_names=[("Windows", "Command")]) for combo in combos]

                # Assign to final output
                shortcuts[name]['mac_combo'] = combo_strings

        # Store name of shortcut under all its locations
        loc = shortcut['Location']
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
        html += "<td>" + "<br />".join(sc['win_combo']) + "</td>"
        html += "<td>" + "<br />".join(sc['mac_combo']) + "</td>"
        html += "<td>" + location + "</td>"
        html += "<td>" + desc + "</td>"
        html += "</tr>"

    html += "</table>"

# Write to file
fpath_out = out_dir + "/" + "shortcuts.htm"
with open(fpath_out, 'w') as f:
    f.write(html)

# Output unique keys
print("Shortcuts of environment " + str(env) + " written to file:")
print(fpath_out)

if not write_update_rh_vars:
    print("Not writing RH variables. Exiting...")
    exit()

# Optional: write to RH variables
fdir = os.getcwd() + os.sep + "variable"
fpath = fdir + os.sep + "Default.var"
tree = ET.parse(fpath)
root = tree.getroot()
vars = {}
for child in root:
    # Skip title tag to avoid parsing issues
    if child.tag == "title":
        continue

    # Reconstruct RH vars mapping
    key = child.attrib["keys"]
    val = child[0][0][0].text
    vars[key] = val

# Update or append shortcuts
for sc in shortcuts:
    readable_name = sc.replace("-", "")
    readable_name = readable_name.replace("+", "And")

    for platform in ["win", "mac"]:
        suffix = "_" + platform.capitalize()
        key_name = "Hotkey_" + readable_name.replace(" ", "_") + suffix
        v = [tag for tag in root.findall('.//keydef[@keys]') if tag.attrib['keys'] == key_name]
        sc_key_name = platform + '_combo'
        text = ", ".join(shortcuts[sc][sc_key_name])
        
        if v:
            # The shortcut already exists!
            # Update
            e = v[0]
            e[0][0][0].text = text
        else:
            # The shortcut is a new one for the RH variables.
            # Create
            e = ET.SubElement(root, "keydef", attrib = {"keys": key_name})
            ec = ET.SubElement(e, "topicmeta")
            ec2 = ET.SubElement(ec, "keywords")
            ec3 = ET.SubElement(ec2, "keyword")
            ec3.text = text

# Prettify XML to maintain line-by-line diffs
ET.indent(tree, space="\t")

tree.write(fpath, encoding='utf-8', xml_declaration=True)

print("RoboHelp variables updated.")