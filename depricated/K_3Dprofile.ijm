/* 3D profile betweeen two points
 *  
 */

//scale should be set manuallyu
var xyscale = 0.056; //nm/pixel
var zscale = 0.7; 
var zfactor =1;
var interpolate = 0;
var GXinc = 1;
/* x, y, z input are in real scale. 
 */
 
str = File.openAsString("");
curdir = File.directory;

newstr = replace(str, ",", ".");
strA = split(newstr, "\n");

for (i = 0; i < strA.length; i++){
	lineA = split(strA[i], "\t");
//	print(lineA[0]);
	x1 = parseFloat(lineA[0]);
	y1 = parseFloat(lineA[1]);
	z1 = parseFloat(lineA[2]);
	x2 = parseFloat(lineA[3]);
	y2 = parseFloat(lineA[4]);
	z2 = parseFloat(lineA[5]);
	dataA = getLine(x1, y1, z1, x2, y2, z2 );
	datastr = "";
	for (j = 0; j<dataA.length; j++){
		if (j==0)
			datastr = datastr + GXinc*j + "\t" + dataA[j];
		else
			datastr = datastr + "\n" + GXinc*j + "\t" + dataA[j];					
	}
	print("sample",i,
		"pnt(",x1, y1, z1,") - (", x2, y2, z2);
	print(datastr);
	for (j = 0; j < dataA.length; j ++){
		setResult("Profile"+IJ.pad(i, 2) + "_x", j, GXinc*j);
		setResult("Profile"+IJ.pad(i, 2) + "_int", j, dataA[j]);
	}
	outtitle = "profile_" + i + ".txt";
	File.saveString(datastr, curdir + outtitle);
}
IJ.renameResults("Profile3D");

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
function getLine(x1, y1, z1, x2, y2, z2 ) {
	dx = x2-x1;
	dy = y2-y1;
	dz = z2-z1;	
	n = sqrt(dx*dx + dy*dy + dz*dz); //real distance between two points
	n2D = round(sqrt(dx*dx + dy*dy)/xyscale); //pixel distance in XYplane
	nz = round(dz/zscale); //pixel depth between two points
	npixXY = round(n/xyscale); //this will be the number of sampling points between two positions
	xinc = dx/npixXY; //increment in X, unit = real 
	yinc = dy/npixXY; //increment in y, unit = real
	zinc = dz/npixXY; //increment in Z, unit = real
	xincpix = xinc/xyscale; //unit = pixel
	yincpix = yinc/xyscale; //unit = pixel
	zincpix = zinc/zscale; //unit = pixel

	GXinc = sqrt(xinc*xinc + yinc*yinc + zinc*zinc); //20110714
	getDimensions(width, height, channels, slices, framess);
	if (!((xinc==0&&n2D==height) || (yinc==0&&n2D==width) || (zinc==0&&nz==slices)))
		npixXY++;
	data = newArray(npixXY);
	rx = x1 / xyscale;
	ry = y1 / xyscale;
	rz = z1 / zscale;
	if (interpolate) {
/*			for (int i=0; i<n; i++) {
			data[i] = getInterpolatedValue(rx, ry);
			rx += xinc;
			ry += yinc;
		}
*/	} else {
		for (i=0; i<npixXY; i++) {
			setSlice(floor(rz));
			data[i] = getPixel((rx+0.5), (ry+0.5));
			rx += xincpix;
			ry += yincpix;
			rz += zincpix;
		}
	}
	return data;
}