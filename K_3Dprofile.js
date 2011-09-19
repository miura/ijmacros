/* 3D profile betweeen two points
 * 
 original macro converted to javascript  
 */

importClass(Packages.org.apache.commons.math.geometry.euclidean.threed.Vector3D);
importPackage(Packages.util.opencsv);
importPackage(Packages.ij.io);
importPackage(Packages.java.io);
importPackage(Packages.java.util);
importClass(Packages.ij.util.Tools);

//scale should be set manuallyu
var xyscale = 0.056; //nm/pixel
var zscale = 0.7; 
var zfactor =1;
var interpolate = 0;
var GXinc = 1;
/* x, y, z input are in real scale. 
 */

/*
str = File.openAsString("");
curdir = File.directory;

newstr = replace(str, ",", ".");
strA = split(newstr, "\n");
*/
od = new OpenDialog("Choose Data File", null);
srcdir = od.getDirectory();
filename = od.getFileName();
fullpath = java.lang.String(srcdir+filename);
//IJ.log(fullpath.getClass());

pntA = PointsfromFile(fullpath);

IJ.log(pntA[0][1].getX());
IJ.log(pntA[0].length);
IJ.log(pntA.length);

imp = IJ.getImage();
get3Dprofile(imp, pntA);

function get3Dprofile(imp, vecA){
	var rt = new ResultsTable();
	for (var i = 0; i < vecA.length; i++){
		var x1 = vecA[i][0].getX();
		var y1 = vecA[i][0].getY();
		var z1 = vecA[i][0].getZ();
		var x2 = vecA[i][1].getX();
		var y2 = vecA[i][1].getY();
		var z2 = vecA[i][1].getZ();
		var dataA = getLine(imp, x1, y1, z1, x2, y2, z2, xyscale, zscale);
		var datastr = "";
		for (var j = 0; j<dataA.length; j++){
			if (j==0)
				datastr = datastr + GXinc*j + "\t" + dataA[j];
			else
				datastr = datastr + "\n" + GXinc*j + "\t" + dataA[j];					
		}
		IJ.log("sample "+ i +" pnt("+x1+ y1+ z1+") - ("+ x2+ y2+ z2);
		IJ.log(datastr);
		for (var j = 0; j < dataA.length; j ++){
			if (rt.getCounter() <= j) rt.incrementCounter();
			rt.setValue("Profile"+IJ.pad(i, 2) + "_x", j, GXinc*j);
			rt.setValue("Profile"+IJ.pad(i, 2) + "_int", j, dataA[j]);
		}
		
		//outtitle = "profile_" + i + ".txt";
		//File.saveString(datastr, curdir + outtitle);
	}
	//rt.updateResults();
	rt.show("Profile3D");
}

//


// reads out 5th column in the CSV file
// using readALL method

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


/*	originally taken from imageprocessor.java in ImageJ
	modified for measurements in 3D stack. 
 	original description:
 	Returns an array containing the pixel values along the
	line starting at (x1,y1) and ending at (x2,y2). For byte
	and short images, returns calibrated values if a calibration
	table has been set using setCalibrationTable().
	@see ImageProcessor#setInterpolate
*/
/*  x, y, z values are in real scale
 *  
 */
function getLine(imp, x1, y1, z1, x2, y2, z2, xys, zs) {
	var dx = x2-x1;
	var dy = y2-y1;
	var dz = z2-z1;	
	var n = Math.sqrt(dx*dx + dy*dy + dz*dz); //real distance between two points
	var n2D = Math.round(Math.sqrt(dx*dx + dy*dy)/xys); //pixel distance in XYplane
	var nz = Math.round(dz/zs); //pixel depth between two points
	var npixXY = Math.round(n/xys); //this will be the number of sampling points between two positions
	var xinc = dx/npixXY; //increment in X, unit = real 
	var yinc = dy/npixXY; //increment in y, unit = real
	var zinc = dz/npixXY; //increment in Z, unit = real
	var xincpix = xinc/xys; //unit = pixel
	var yincpix = yinc/xys; //unit = pixel
	var zincpix = zinc/zs; //unit = pixel

	GXinc = Math.sqrt(xinc*xinc + yinc*yinc + zinc*zinc); //20110714
	//getDimensions(width, height, channels, slices, framess);
	width = imp.getWidth();
	height = imp.getHeight();
	slices = imp.getStackSize();		
	if (!((xinc==0&&n2D==width) || (yinc==0&&n2D==height) || (zinc==0&&nz==slices)))
		npixXY++;
	//data = newArray(npixXY);
	data = [];
	var rx = x1 / xys;
	var ry = y1 / xys;
	var rz = z1 / zs;
	if (interpolate) {
/*			for (int i=0; i<n; i++) {
			data[i] = getInterpolatedValue(rx, ry);
			rx += xinc;
			ry += yinc;
		}
*/	} else {
		var ip;
		for (var i=0; i<npixXY; i++) {
			//setSlice(floor(rz));
			ip = imp.getStack().getProcessor(Math.floor(rz));
			//data[i] = ip.getPixel((rx+0.5), (ry+0.5));
			data.push(ip.getPixel((rx+0.5), (ry+0.5)));
			rx += xincpix;
			ry += yincpix;
			rz += zincpix;
		}
	}
	return data;
}
