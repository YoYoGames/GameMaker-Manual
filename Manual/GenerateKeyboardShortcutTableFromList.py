import csv
shortcutList="./ManualShortcuts.csv"
table="./ManualShortcutsTable.txt"

with open(shortcutList) as csvfile:
	with open(table, "w") as tablefile:
		shortcutReader = csv.reader(csvfile)
		for row in shortcutReader:
			tableRow = "<tr>\n"
			#Ignore row[0] - name field
			tableRow += "\t<td>"+row[1]+"</td>\n"
			tableRow += "\t<td>"+row[2]+"</td>\n"
			tableRow += "\t<td>"+row[3]+"</td>\n"
			tableRow += "\t<td>"+row[4]+"</td>\n"
			tableRow += "</tr>\n"
			tablefile.write(tableRow)