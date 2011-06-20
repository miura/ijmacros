//getFileList(directory)
/*

merging two XLS files laterally, not concatenation. 

Oriol +
Kota Miura (cmci.embl.de) 20101214
*/
firstfile = File.openAsString("");
secondfile = File.openAsString("");

destinationPath = File.directory;

firstA = split(firstfile, "\n");
secondA = split(secondfile, "\n");

if (firstA.length>secondA.length) 
	tablelength = firstA.length;
else
	tablelength = secondA.length;

mergedA = newArray(tablelength);

for (i = 0; i < tablelength; i++){
	mergedA[i] = "";
	if (i < firstA.length) {
		mergedA[i] =  mergedA[i] + firstA[i]; 
		mergedA[i] =  mergedA[i] +  "\t";
	} else
		mergedA[i] += "\t\t\t";

	if (i < secondA.length) {
		mergedA[i] = mergedA[i] + secondA[i];
		mergedA[i] = mergedA[i] + "\t";
	} else
		mergedA[i] += "\t\t\t";

	print(mergedA[i]);
}

merged = "";
for (i = 0; i<mergedA.length; i++) {
	merged += mergedA[i];
	merged += "\n";
}
print(merged);

File.saveString(merged, destinationPath + File.separator + "test.xls" );
