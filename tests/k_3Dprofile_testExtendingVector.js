

var Gradius = 0.1;
var Gextends = 0.5;

//importing libraries
importClass(Packages.org.apache.commons.math.geometry.euclidean.threed.Vector3D);
importClass(Packages.org.apache.commons.math.stat.descriptive.DescriptiveStatistics);
importPackage(Packages.util.opencsv);
importPackage(Packages.ij.io);
importPackage(Packages.java.io);
importPackage(Packages.java.util);
importClass(Packages.ij.util.Tools);

//scale should be set manually
var xyscale = 0.056; //nm/pixel
var zscale = 0.7; 
var zfactor =1;
var interpolate = 0;
var GXinc = 1;

Gdiscstr = ""; //to check measured points

//x, y, z input are in real scale. 
od = new OpenDialog("Choose Data File", null);
srcdir = od.getDirectory();
filename = od.getFileName();
fullpath = java.lang.String(srcdir+filename);
//IJ.log(fullpath.getClass());

pntA = PointsfromFile(fullpath);
extpntA = extendVector(pntA);

for (var i = 0; i < pntA.length; i++){
	IJ.log("orig:" + pntA[i][0].getX() + ", "+ pntA[i][0].getY() + ", "+ pntA[i][0].getZ() + ", ");
	IJ.log("> ext:" + extpntA[i][0].getX() + ", "+ extpntA[i][0].getY() + ", "+ extpntA[i][0].getZ() + ", ");
}

//converts CVS file to a two element array of two Vecotr 3D arrays. 
function PointsfromFile(datafilepath){
	var dataA = new ArrayList();
	var pointsA = [];	//javascript array
	//filepath = java.lang.String(dir + sp + filesA[i]);
	if (datafilepath.endsWith(".txt") || datafilepath.endsWith(".csv")) {
		IJ.log(datafilepath);
		readCSV(datafilepath, dataA); //dataA then is a ArrayList of java String arrays
	} else {
		IJ.log("problem reading: " + datafilepath);
	}
	var datait = dataA.iterator();
	while (datait.hasNext()){
		//IJ.log(datait.next()[0]);
		var carray = datait.next();
		var p1 = Vector3D(carray[0], carray[1], carray[2]);
		var p2 = Vector3D(carray[3], carray[4], carray[5]);
		pointsA.push([p1, p2]);
	}
	IJ.log("=== point pairs loaded from " + datafilepath);	
	return pointsA; 		  
}

function readCSV(filepath, dataA) {
    var reader = new CSVReader(new FileReader(filepath), "\t");
    var ls = reader.readAll();
    var it = ls.iterator(); 
    while (it.hasNext()){
        var carray = it.next();
        dataA.add(carray);
        //IJ.log(carray[4]); 
    }
}

//extend vector on each side. 
function extendVector(pointsA){
	var extpointsA = [];
	for (var i = 0; i < pointsA.length; i++) {
		var axisVec = pointsA[i][1].subtract(pointsA[i][0]);
		var axisNormalizedVec = axisVec.normalize();
		extpointsA.push([pointsA[i][0].add(-1 * Gextends, axisNormalizedVec), pointsA[i][1].add(Gextends, axisNormalizedVec)]);				
	}
	return extpointsA;
}
