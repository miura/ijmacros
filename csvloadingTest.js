importClass(Packages.ij.util.Tools);
importPackage(Packages.util.opencsv);

var jio    = new JavaImporter();
jio.importPackage(Packages.java.io);

var args = getArgument();
var argA = Tools.split(args, ":");
var imgfilepath = argA[0];
var datafilepath = argA[1];

imp = IJ.openImage(imgfilepath);


var dataA = new ArrayList();
//filepath = java.lang.String(dir + sp + filesA[i]);
if (datafilepath.endsWith(".txt") || datafilepath.endsWith(".csv")) {
	IJ.log(datafilepath);
	readCSV(datafilepath, dataA);
} else {
	IJ.log("problem reading: " + datafilepath);
}

var datait = dataA.iterator();
while (datait.hasNext()){
	IJ.log(datait.next()[0]);
}

function readCSV(filepath, dataA) {
    var reader = new CSVReader(new FileReader(filepath), ",");
    var ls = reader.readAll();
    var it = ls.iterator(); 
    while (it.hasNext()){
        var carray = it.next();
        dataA.add(carray);
        //IJ.log(carray[4]); 
    }
}
 