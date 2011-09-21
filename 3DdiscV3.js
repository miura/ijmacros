/*
DdiscV2.js
Wani's 3D intensity profileing extended. 
ver2: no involvement of scaling / pixel
ver3: calculate all in real scale > convert to voxel positions. 
 */

//http://commons.apache.org/math/apidocs/org/apache/commons/math/geometry/euclidean/threed/Vector3D.html
importClass(Packages.org.apache.commons.math.geometry.euclidean.threed.Vector3D);

ww = 100;
hh = 100;
dd = 31;
var imp = IJ.createImage("test", "8-bit Black", ww, hh, dd);

var xyscale = 0.056; // um/pixel
var zscale = 0.7;    // um/pixel
//var zscale = 0.056;    // um/pixel
var zfactor =1;
var interpolate = 0;
var GXinc = 1;

var wws = ww * xyscale;
var hhs = hh * xyscale;
var dds = dd * zscale;

//center of the stack, example starting point of vector
var v_os = new Vector3D(wws/2, hhs/2, dds/2);

//example vector connectiong two points
var v_se = new Vector3D(0.1, 0.1, 0.1);

//radius of the circular area permendicular to vse
var radius = 0.5; 

pntA = return2Ddisc(v_os, v_se, radius, xyscale);
IJ.log("pntA length " + pntA.length);

voxlesA = realpos2voxelpos(pntA, xyscale, zscale);
IJ.log("voxlesA length " + voxlesA.length);

for (var i = 0; i < voxlesA.length; i++){
	var vpoint = voxlesA[i];
//	IJ.log("position: " + vpoint.getX() + ", "+ vpoint.getY() + ", "+ vpoint.getZ());
	if ((vpoint.getZ() >= 1) && (vpoint.getZ() <= dd)){
		var ip = imp.getStack().getProcessor(vpoint.getZ());
/*		this is for checking if redundant pixels are listed
		var pixval =  ip.getPixelValue(vpoint.getX(), vpoint.getY()); 
		ip.putPixel(vpoint.getX(), vpoint.getY(), pixval+1);	
*/
		ip.putPixel(vpoint.getX(), vpoint.getY(), 255);
	}
}

imp.show();



//******************** functions ********************//


// vpointsA is an array of Vector3D in real scale. 
// converts real scale coordinates to voxel coordinates
// at the same time, removes redunduncy.  
// 	xys: xyscale
//  zs: zscale
function realpos2voxelpos(vpointA, xys, zs){
	voxA = [];
	for (var i = 0; i < vpointA.length; i++){
		var vpoint = pntA[i];		
		var xpos = Math.round(vpoint.getX() / xys);
		var ypos = Math.round(vpoint.getY() / xys);		
		var zpos = Math.round(vpoint.getZ() / zs) + 1;
		var cv3 = new Vector3D(xpos, ypos, zpos);
		IJ.log("" + xpos +", "+ ypos +", "+ zpos);
		var flag = 1; 
		for (var j = 0; j < voxA.length; j ++)
			if (voxA[j].equals(cv3)) flag = 0;	
		if (flag == 1) voxA.push(cv3);
	}
	return voxA;	
}

//parameters
//	vs: vector from origin to the starting point of a givien profile
//	vse: vector between starting and end point of a given profile
//	r: radius of the disc
//	xys: xyscale, for incrementing the scan
function return2Ddisc(vs, vse, r, xys){
	//*** from here, Wani's algorithm ***

	//generate a vector va on disc, centered at the origin (0,0,0).
	var vaN = vse.orthogonal(); 	// returned vector is already normalized

	IJ.log("starting point x0: " + vs.getX() + "," + + vs.getY() + "," + vs.getZ());

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
		 		var vpoint = new Vector3D(1, vs, 1, vscan);
				vpointA.push(vpoint);
		 	} 
		 }
	}
	return vpointA;
}


