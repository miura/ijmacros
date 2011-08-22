// Example javascript for loading data from a series of CSV files in a folder.
// 
// Assumes that these files are data output from other processing, 
// and all data has same format. 
// This script uses openCSV, which is included in Fiji. 
// for more details on openCSV, visit the URLbelow. 
// http://opencsv.sourceforge.net/
// 20110822 Kota Miura (miura@embl.de) 

importPackage(Packages.util.opencsv);
importPackage(Packages.java.io);

//path = "/Users/miura/Dropbox/data"; //unix
path = "C:/dropbox/My\ Dropbox/data"; //win

dir = new File(path);
filesA = dir.list();
sp = File.separator;

for (var i=0; i<filesA.length; i++) {
	filepath = java.lang.String(dir + sp + filesA[i]);
	if (filepath.endsWith(".txt") || filepath.endsWith(".csv")) {
        	IJ.log(filepath);
        	readCSV(filepath);
	} else {
        	IJ.log("Igonored: " + filepath);
	}
}

// reads out 5th column in the CSV file
// using readALL method
function readCSV(filepath) {
	reader = new CSVReader(new FileReader(filepath), " ");
	ls = reader.readAll();
	it = ls.iterator(); 
	while (it.hasNext()){
		carray = it.next();
		IJ.log(carray[4]); 
	}
}

// reads out 5th column in the CSV file
// using readNext method, output is similar to readAll
function readCSVbyLine(filepath) {
	reader = new CSVReader(new FileReader(filepath), " ");
	while ((nextLine = reader.readNext()) != null) {
        	// nextLine[] is an array of values from the line
        	IJ.log(nextLine[4]);
    	}    
}      
