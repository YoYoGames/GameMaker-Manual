import csv
import re

shortcutList="./ManualShortcuts.csv"
table="./ManualShortcutsTable.htm"

# Replace the Mac characters using simple regexes
def replaceMacChars(string):
	string = re.sub("⌘$", r"CMD", string)
	string = re.sub("⌫$", r"Delete", string)
	string = re.sub("⎋$", r"Escape", string)
	string = re.sub("⌃$", r"CTRL", string)
	string = re.sub("⇧$", r"SHIFT", string)
	string = re.sub("⌥$", r"ALT", string)
	string = re.sub("⇥$", r"Tab,", string)
	string = re.sub("⌘([^,])", r"CMD+\1", string) # Command
	string = re.sub("⌫([^,])", r"Delete+\1", string) # Delete
	string = re.sub("⌃([^,])", r"CTRL+\1", string) # Control
	string = re.sub("⇧([^,])", r"SHIFT+\1", string) # Shift
	string = re.sub("⌥([^,])", r"ALT+\1", string) # Alt
	string = re.sub("⇥([^,])", r"Tab+\1", string) # Tab
	return string


previousSection = ""

# Is this the first table we're writing?
first = True

with open(shortcutList, encoding="utf-8") as csvfile:
	with open(table, "w", encoding="utf-8") as tablefile:
		shortcutReader = csv.reader(csvfile)
		
		tablefile.write("<!DOCTYPE html>\n<html><head></head><body>")
		
		for row in shortcutReader:
			print(row)
			name, winKeyCombo, macKeyCombo, section, description = row
			
			# Insert <table> tag so we can copy-paste directly from the table
			# (including table formatting!)
			if section != previousSection:
				if not first:
					tablefile.write("</table>")
				
				tablefile.write("<h2>" + section + "</h2>")
				tablefile.write("<table><tr><th>Windows Key Binding</th><th>macOS Key Binding</th><th>Scope</th><th>Description</th></tr>\n")

			tableRow = "<tr>\n"
			#Ignore row[0] - name field
			
			# Windows key combination
			tableRow += "\t<td>"+winKeyCombo+"</td>\n"
			
			# MacOS key combination
			macKeyCombo = replaceMacChars(row[2])
			tableRow += "\t<td>"+macKeyCombo+"</td>\n"
			
			# Category/Scope/Section
			previousSection = section
			tableRow += "\t<td>"+section+"</td>\n"
			
			# Description
			if description:
				tableRow += "\t<td>"+description+"</td>\n"
			else:
				tableRow += "\t<td>"+name+" ***</td>\n"
			
			tableRow += "</tr>\n"
			tablefile.write(tableRow)
			
			first = False

		# Close the last table tag too
		tablefile.write("</table>\n")
		tablefile.write("</body>\n")
		tablefile.write("</html>\n")
