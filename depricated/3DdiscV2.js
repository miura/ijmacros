importClass(Packages.org.apache.commons.math.geometry.euclidean.threed.Vector3D);

ww = 100;
hh = 100;
dd = 31;
imp = IJ.createImage("test", "8-bit Black", ww, hh, dd);

//center of the stack, example starting point of vector
vs = new Vector3D(Math.floor(ww/2), Math.floor(hh/2), Math.floor(dd/2))

//example vector connectiong two points
vse = new Vector3D(1, 1, 1);

IJ.log("starting point x0: " + vs.getX() + "," + + vs.getY() + "," + vs.getZ());

//radius of the circular area permendicular to vse
r = 10; 

//*** from here, Wani's algorithm ***

//generate a vector va on disc, centered at the origin (0,0,0).
// already normalized
vaN = vse.orthogonal();

//vb, a vector perpendicular to both vse and va
vb = vse.crossProduct(vaN);
//normalize vb
vbN = vb.normalize();

//bottom-left corner vector vbase.
//vaN and vbN, opposite of each multiplied by radius r and added
vbase = new Vector3D(r, vaN.negate(), r, vbN.negate());

for (j = 0; j < r*2 + 1; j++){
	 for (i = 0; i < r*2 + 1; i++){
	 	vscan = new Vector3D(1, vbase, i, vaN, j, vbN);
	 	IJ.log("" + i + ", " + j);	 	
	 	if (vscan.getNorm() < r){
	 		IJ.log("... ... on the disk");
	 		vpoint = new Vector3D(1, vs, 1, vscan);
			if ((vpoint.getZ()>= 0) && (vpoint.getZ() < dd)){
				ip = imp.getStack().getProcessor(vpoint.getZ()+1);
				ip.putPixel(vpoint.getX(), vpoint.getY(), 255);
				IJ.log("... ... plotted");
			} else 
				IJ.log("... ... outside stack");	 		 
	 	} else {
	 		IJ.log("... ... outside disk");
	 	}
	 }
}
imp.show();
