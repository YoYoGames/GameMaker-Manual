### Python script to generate copy-pasteable HTML tables from JSON files
###
### Provide the full directory path to the .json files as the command line argument.
### The output HTML file will also be placed there.
### For example: CMD > python GenerateKeyboardShortcutTableFromJson.py "C:/Users/Dev/Documents/Manual/" -name_as_desc
###
### You can provide an optional argument: 
### 
### -name_as_desc: Add this to write the hotkey's name as the description.
### 
### Important: Technically, the JSON cannot contain trailing commas, this isn't supported
###            using the built-in json module. Though it is supported through the yy_load function.
###

import sys
import json
import re
from collections import OrderedDict

def yy_load(file):
    """ Load json from a file that possibly contains trailing commas """
    # Do some tricky regex substitution
    # so we can use the json module
    data_string = ''.join(file.readlines())
    data_string = re.sub("(,)(\s*[]}])","\g<2>", data_string)

    # Now we can import using the json module
    return json.loads(data_string)

# Utility functions
def get_combo_string(combo):
    if not combo:
        combo_string = ""
    else:
        modifier = [key for key in combo['Modifier'].split(", ") if key != "None"]
        combo_string = " + ".join([*modifier, combo['Keys']])
    return combo_string

# Default names
fname_win_hotkeys = "default_hotkeys.json"
fname_mac_hotkeys = "mac_hotkeys.json"

# Whether to use the shortcut's name as the description
name_as_desc = False

# Handle parameters received from command line
if len(sys.argv) == 1:
    print("ERROR - The input/output directory should be provided. Exiting...")
    exit()
else:
    fdir = sys.argv[1]
    name_as_desc = (len(sys.argv) == 3 and sys.argv[2] == "-name_as_desc")

# Data structures
input = []                              # input from file
shortcuts = dict()                      # maps shortcut name => shortcut data
shortcuts_per_location = OrderedDict()  # stores shortcuts under locations

# First read the Windows defaults file
with open(fdir + "/" + fname_win_hotkeys, 'r', encoding="utf-8") as f:
    # Load all the data
    # input = json.load(f)              # risk of errors if trailing commas are present
    input = yy_load(f)                  # regex-replace variety that fixes things

    # Add items under their respective locations (i.e. "group" per location)
    for shortcut in input:
        # Get unique name
        name = shortcut['Name']

        # Nothing to do for unlisted shortcuts?
        if 'IsUnlisted' in shortcut:
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

        # Store name of shortcut under all its locations
        loc = shortcut['Location']
        locations = [loc] if (type(loc) == str) else loc

        for location in locations:
            # Make sure a list exists under the key before writing to it
            if location not in shortcuts_per_location:
                shortcuts_per_location[location] = OrderedDict()
            
            # Add the shortcut
            shortcuts_per_location[location][name] = name

# Then add the combos in the macOS defaults file
with open(fdir + "/" + fname_mac_hotkeys, 'r') as f:
    # Load all the data
    input = yy_load(f)

    # Add items under their respective locations
    for shortcut in input:
        # Get unique name
        name = shortcut['Name']

        # Nothing to do for unlisted shortcuts
        if name not in shortcuts:
            continue
        
        # Get this shortcut's combo(s)
        cbo = shortcut['Combo']
        combos = [cbo] if type(cbo) is not list else cbo
        combo_strings = [get_combo_string(combo) for combo in combos]

        # Just overwrite the macOS combo under the right name here
        shortcuts[name]['mac_combo'] = combo_strings

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
with open(fdir + "/" + "shortcuts.htm", 'w') as f:
    f.write(html)
