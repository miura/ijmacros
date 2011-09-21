/* 3D profile betweeen two points
 * 
 original macro converted to javascript  
 Kota Miura (miura@embl.de)
 20110920 added with "wide" profile measurements

workflow: prepare a tab-delimited data file with 
a pair of 3D coordinates per line
(6 numbers per line). Run this script, and 
in dialog window choose the file, then 3D intensity profile
in the top-image window will be calculated and shown in the 
Results table. 

 requirements: apache commons math 3.0< (update to the latest Fiji)
 */

//**** to measure with certain width, change here to none-zero value. (in real scale) ****
var Gradius = 0.1;

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



//x, y, z input are in real scale. 
od = new OpenDialog("Choose Data File", null);
srcdir = od.getDirectory();
filename = od.getFileName();
fullpath = java.lang.String(srcdir+filename);
//IJ.log(fullpath.getClass());

pntA = PointsfromFile(fullpath);

//IJ.log(pntA[0][1].getX());
//IJ.log(pntA.length);

imp = IJ.getImage();

var width = imp.getWidth();
var height = imp.getHeight();
var slices = imp.getStackSize();
	
if (Gradius == 0) 
	get3Dprofile(imp, pntA);
else
	get3DprofileWide(imp, pntA, Gradius);

function get3Dprofile(imp, vecA){
	var rt = new ResultsTable();
	for (var i = 0; i < vecA.length; i++){
		var x1 = vecA[i][0].getX();
		var y1 = vecA[i][0].getY();
		var z1 = vecA[i][0].getZ();
		var x2 = vecA[i][1].getX();
		var y2 = vecA[i][1].getY();
		var z2 = vecA[i][1].getZ();
		//var dataA = getLine(imp, x1, y1, z1, x2, y2, z2, xyscale, zscale);
		var dataA = getLineVec(imp, vecA[i][0], vecA[i][1], xyscale, zscale);
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
	rt.show("Profile3Ds");
}

function get3DprofileWide(imp, vecA, radius){
	var rt = new ResultsTable();
	for (var i = 0; i < vecA.length; i++){
	//for (var i = 0; i < 1; i++){		//test
		//var dataA = getLineVec(imp, vecA[i][0], vecA[i][1], xyscale, zscale);
		//returned value is an array of disc stats objects
		var dataA = getLineVecWide(imp, vecA[i][0], vecA[i][1], xyscale, zscale, radius); 
		for (var j = 0; j < dataA.length; j ++){
			if (rt.getCounter() <= j) rt.incrementCounter();
			rt.setValue("Profile"+IJ.pad(i, 2) + "_x", j, GXinc*j);
			rt.setValue("Profile"+IJ.pad(i, 2) + "_N", j, dataA[j].npnts);
			rt.setValue("Profile"+IJ.pad(i, 2) + "_int", j, dataA[j].meanint);
			rt.setValue("Profile"+IJ.pad(i, 2) + "_std", j, dataA[j].sdint);
			rt.setValue("Profile"+IJ.pad(i, 2) + "_sx", j, dataA[j].x);
			rt.setValue("Profile"+IJ.pad(i, 2) + "_sy", j, dataA[j].y);
			rt.setValue("Profile"+IJ.pad(i, 2) + "_sz", j, dataA[j].z);														
		}
		//outtitle = "profile_" + i + ".txt";
		//File.saveString(datastr, curdir + outtitle);
	}
	//rt.updateResults();
	rt.show("Profile3Dw");
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

//updated version with apache math Vector3D
// vos: starting point position vector
// voe: end point position vector
function getLineVec(imp, vos, voe, xys, zs) {
	vse = new Vector3D(1, voe, 1, vos.negate()); // the profile vector, origined at 0
	var n = vse.getNorm();  //real distance between two points
	var npixXY = Math.round(n/xys); //this will be the number of sampling points between two positions
		
	var incVec = new Vector3D(1/npixXY, vse);	//incremental vector
	GXinc = incVec.getNorm(); //20110714

	var width = imp.getWidth();
	var height = imp.getHeight();
	var slices = imp.getStackSize();
	
	data = [];
	if (interpolate) {
/*			for (int i=0; i<n; i++) {
			data[i] = getInterpolatedValue(rx, ry);
			rx += xinc;
			ry += yinc;
		}
*/
	} else {
		var ip;
		for (var i=0; i<=npixXY; i+=1) {
			var voss = new Vector3D(1, vos, i/npixXY, vse);
			var zcoord = Math.floor(voss.getZ()/zs) + 1; //zposiiton in slice (>=1), was 0 before
			if ((zcoord > 0) && (zcoord <= slices)) {
				ip = imp.getStack().getProcessor(zcoord);
				var xcoord = Math.round(voss.getX()/xys);
				var ycoord = Math.round(voss.getY()/xys);
				data.push(ip.getPixel(xcoord, ycoord));
			} else {
				IJ.log("...out of stack at " + i + "th sampling point");
			}
		}
	}
	return data;
}

//updated version with apache math Vector3D
// vos: starting point position vector
// voe: end point position vector
// a version with certain width in the profile. 
function getLineVecWide(imp, vos, voe, xys, zs, radius) {
	vse = new Vector3D(1, voe, 1, vos.negate()); // the profile vector, origined at 0
	var n = vse.getNorm();  //real distance between two points
	var npixXY = Math.round(n/xys); //this will be the number of sampling points between two positions
		
	var incVec = new Vector3D(1/npixXY, vse);	//incremental vector
	GXinc = incVec.getNorm(); //20110714

	var width = imp.getWidth();
	var height = imp.getHeight();
	var slices = imp.getStackSize();
	
	data = [];
	if (interpolate) {
/*			for (int i=0; i<n; i++) {
			data[i] = getInterpolatedValue(rx, ry);
			rx += xinc;
			ry += yinc;
		}
*/
	} else {
		var ip;
		for (var i=0; i<=npixXY; i+=1) {
			var discpntA = return2Ddisc(vos, vse, i/npixXY, radius, xys);
			//IJ.log("... disc points" + discpntA.length);
			var voxlesA = realpos2voxelpos(discpntA, xys, zs);
			var discdataA = [];
			//IJ.log("... voxels:" + voxlesA.length);
			for(var j = 0; j < voxlesA.length; j++){
				var cv = voxlesA[j]; //vector3d
				if (	((cv.getZ() > 0) && (cv.getZ() <= slices))	&&
				   		((cv.getX() >= 0) && (cv.getX() < width))	&&
				   		((cv.getY() >= 0) && (cv.getY() < height)) ) 	{
					//IJ.log("zpos = " + cv.getZ());
					var ip = imp.getStack().getProcessor(cv.getZ());
					var pixval = ip.getPixel(cv.getX(), cv.getY());										
					discdataA.push(pixval);
					//IJ.log("pixval " + pixval);
				} else {
					IJ.log("...out of stack at " + i + "th sampling point");
					//discdataA.push(0);
				}
			}
			//IJ.log("discdataA " + discdataA.length);
			var vinc;
			if (i != 0)
				vinc = new Vector3D(1, vos, i/npixXY, vse);
			else
				vinc = vos;
			thisdisc = 	constructDiscStat(vinc, discdataA);	//discO object			
			data.push(thisdisc);
		}
	}
	return data;
}

// dA is an instensity array
// cv is a Vector3D, center of the disc
// returns a discO, disc object containing intensity stats. 
function constructDiscStat(cv, dA){
	var stats = new DescriptiveStatistics();

	// Add the data from the array
	for(var i = 0; i < dA.length; i++){ 
        stats.addValue(dA[i]);
        //IJ.log(dA[i]);
	}

	var mean = stats.getMean();
	var std = stats.getStandardDeviation();
	var total = stats.getSum();
	IJ.log("...mean int " + mean);
	IJ.log("... ... std " + std);
	adisc = new discO(cv.getX(), cv.getY(), cv.getZ(), dA.length, mean, std, total, dA);
	return adisc;
}


//Object for single node in profile
// to store statistics
function discO(x, y, z, npnts, meanint, sdint, totalint, intA){
	this.x = x;
	this.y = y;
	this.z = z;
	this.npnts = npnts;
	this.meanint = meanint;
	this.sdint = sdint;
	this.totalint = totalint;
	this.intA = intA;
}


//******************** 2D disc  functions ********************//


/*
pntA = return2Ddisc(v_os, v_se, radius, xyscale);
IJ.log("pntA length " + pntA.length);

voxlesA = realpos2voxelpos(pntA, xyscale, zscale);
IJ.log("voxlesA length " + voxlesA.length);
*/

// vpointsA is an array of Vector3D in real scale. 
// converts real scale coordinates to voxel coordinates
// at the same time, removes redunduncy.  
// 	xys: xyscale
//  zs: zscale
//	returns javascript array containing Vector3D of voxels
function realpos2voxelpos(vpointA, xys, zs){
	voxA = [];
	for (var i = 0; i < vpointA.length; i++){
		var vpoint = vpointA[i];		
		var xpos = Math.round(vpoint.getX() / xys);
		var ypos = Math.round(vpoint.getY() / xys);		
		var zpos = Math.round(vpoint.getZ() / zs) + 1;
		var cv3 = new Vector3D(xpos, ypos, zpos);
/* this part eliminates overlapped voxels, but omit this part after taliking with Wani
		var flag = 1; 
		for (var j = 0; j < voxA.length; j ++)
			if (voxA[j].equals(cv3)) flag = 0;	
		if (flag == 1)
*/ 
			voxA.push(cv3);
		
	}
	return voxA;	
}

//parameters
//	vs: vector from origin to the starting point of a givien profile
//	vse: vector between starting and end point of a given profile
//	r: radius of the disc
//	xys: xyscale, for incrementing the scan
//	returned value is a javascript array with positional Vector3D representing the disc (in real scale)	
function return2Ddisc(vs, vseOriginal, scale, r, xys){
	//*** from here, Wani's algorithm ***
	//var vse;
	//generate a vector va on disc, centered at the origin (0,0,0).
	var vse = new Vector3D(scale, vseOriginal);
	if (scale ==0)
		vse = vseOriginal;
		
	var vaN = vse.orthogonal(); 	// for the first point	

	//IJ.log("starting point x0: " + vs.getX() + "," + + vs.getY() + "," + vs.getZ());
	IJ.log(""+scale+ " of profile");
	//vb, a vector perpendicular to both vse and va
	var vb = vse.crossProduct(vaN);
	//normalize vb
	var vbN = vb.normalize();


	//bottom-left corner vector vbase.
	//vaN and vbN, opposite of each multiplied by radius r and added
	var vbase = new Vector3D(r, vaN.negate(), r, vbN.negate());
	var vpointA = [];
	for (var j = 0; j < r*2 + 1; j += xys){
		 for (var i = 0; i < r*2 + 1; i += xys){
		 	var vscan = new Vector3D(1, vbase, i, vaN, j, vbN);
		 	if (vscan.getNorm() < r){
		 		//var vpoint = new Vector3D(1, vs, 1, vscan);
		 		var vpoint = new Vector3D(1, vs, 1, vse, 1, vscan);
				vpointA.push(vpoint);
		 	} 
		 }
	}
	//IJ.log("vse_inc" + vse.getX() + ", "+ vse.getY() + ", "+ vse.getZ() + ", ");
	//IJ.log("vbase" + vbase.getX() + ", "+ vbase.getY() + ", "+ vbase.getZ() + ", ");
	return vpointA;
}


//**************** none-vec version, IJ style ******* (faster, as it seems)

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
