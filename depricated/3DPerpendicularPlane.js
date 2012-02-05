
ww = 100;
hh = 100;
dd = 31;
imp = IJ.createImage("test", "8-bit Black", ww, hh, dd);

//center of the stack, starting point of vector
x0 = [Math.floor(ww/2), Math.floor(hh/2), Math.floor(dd/2)]; 
iv = [1,1,1]; // an example vector. x0 + iv = x1, the end point

IJ.log("starting point x0: " + x0[0] + "," + + x0[1] + "," + x0[2]);

//radius of the circular area permendicular to iv
r = 20; 

// set a 3D roi top-left corner for scanning to get Z 
roix = x0[0] - r;
roiy = x0[1] - r;

//scannong 2r x 2r square
for (var j = -1*r; j < r; j++){
	for (var i =  -1*r; i < r; i++){
		//calculate z, using dot product
		var k = Math.floor(calcZpos(i, j, iv[0], iv[1], iv[2]));
		
		var curx = i + x0[0]; //actual X position within image
		var cury = j + x0[1]; //actual Y position within image		
		var curz = k + x0[2]; //actual Z position within image		

		//just to check resutlts in the log window
		var realcoords = "" + curx + "," +cury + "," +curz;
		var normcoords = "" + i + "," + j + "," +k;
		IJ.log(realcoords + "(" + normcoords + ")");

		//test if current position is 
		//within a distance from the origin x0
		//if true, that would be the positive position
		if (testInsideSphere(i, j, k, r) == true){
			IJ.log("... in the circular plane")
			if ((curz >= 0) && (curz < dd)){
				ip = imp.getStack().getProcessor(curz+1);
				ip.putPixel(curx, cury, 255);
				IJ.log("... ... plotted");
			} else 
				IJ.log("... ... outside stack");
		}
		
	}
}
imp.show();

function calcZpos(thisx, thisy, refx, refy, refz){
	var thisz = 0;
	thisz = -1 * (thisx*refx + thisy*refy) / refz;
	return thisz
}

function testInsideSphere(tx, ty, tz, tr){
	var inside = false;
	var trsq = tx*tx + ty*ty + tz*tz;
	if (trsq < tr*tr)
		inside = true;
	return inside;
}







