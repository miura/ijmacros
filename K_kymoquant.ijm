/* K_textureOrientation.ijm

Kota Miura, CMCI EMBL Heidelberg (miura at embl dot de) +49 6221 387 404

Kymograph measurement (Peter@Ellenberg)

requirements: a kymograph with X-axis being space, and y-axis being time or frames. 
tip: Gauss blurring increases precision of the measurement. 

081030 Commented out earlier version macros. validation studies are in 
	- ConvolutionKernleStudy.pxp : compared scharr kernel and sobel kernel. Use of rotating stripes.
	-anglemeasurement_artificialRotation.pxp
081105 upon Peters suggestion, tangent was corrected for x = displacement, y = time (frames)	
100303 renamed to K_kymoquant.ijm 
  */

var ovalROIx =1;
var ovalROIy =1;
var ovalROIww =10;

/*
macro "Orientation detection" {
	origID = getImageID();
	print(getTitle());
	kymographVelMeasure(origID, 0, 0);
}

//

macro "Orientation detection + show rotation stack" {
	origID = getImageID();
	print(getTitle());
	kymographVelMeasure(origID, 1, 1);
}

macro "-"{}


macro "Measure rect ROI" {
	MeasROIcore(0);
}

macro "Measure rect ROI show rotation stack" {
	MeasROIcore(1);
}
*/

function MeasROIcore(stackswitch){

	if (selectionType()!=0) exit("need a rectangular ROI");
	getSelectionBounds(x, y, width, height);
	if ((height<30) || (width<30)) exit("rectangular ROI should have a width and height larger than 30");
	run("Copy");

	print(getTitle());
	print("Frame "+y+" to "+(y+height));

	setBatchMode(true);
	newImage("temppart", "8-bit Black", width , height, 1);
	duporgID = getImageID();
	run("Paste");
	origID = getImageID();
	if (stackswitch) {
		kymographVelMeasure(origID, 1, 1);
	} else {
		kymographVelMeasure(origID, 0, 0);
	}
	selectImage(duporgID);
	close();
	setBatchMode("exit and display");
}

// ver 1. Obsolete
function kymographVelMeasure(origID,createstack, listresults) {
	getDimensions(ww, hh, channels, slices, frames);
	angleincrement = 1;
	frames = floor(360/angleincrement); 

	convop ="text1=[1 0 -1\n2 0 -2\n1 0 -1\n] normalize";		//vertical sobel filter
	//convop ="text1=[3 0 -3\n10 0 -10\n3 0 -3\n] normalize";	//vertical Scharr filter

	totalintA = newArray(frames);

	rotcanvasww = round(sqrt(pow(ww, 2)+pow(hh,2)) * 1.2);
	if (createstack) {
		newImage("stack", "8-bit Black", rotcanvasww , rotcanvasww , frames );
		stackID = getImageID();
	}
	canvasop = "width="+rotcanvasww +" height="+rotcanvasww +" position=Center zero";

	//rectangular ROI
	ROIwidth = ww - 2*5;	//5 pixel inside
	ROIheight = hh - 2*5;	//5 pixel inside
	ROIx = rotcanvasww/2  - ROIwidth /2;
	ROIy = rotcanvasww/2  - ROIheight /2;
	
	//OvalROI
	ovalROIww =ww * 0.85;				//0.95  to exclude ege effect by convolution
 	ovalROIx = rotcanvasww/2 - ovalROIww/2 ;
	ovalROIy = rotcanvasww/2 - ovalROIww/2 ;

	if (listresults) run("Clear Results");

	setBatchMode(true);
	for(i=0; i<frames; i++) {
		selectImage(origID);
		run("Duplicate...", "title=[temp]");
		dupID = getImageID();
		run("Canvas Size...", canvasop);
		op = "angle="+(i*angleincrement) +" grid=0";
		run("Arbitrarily...", op);
		run("Convolve...", convop);
		makeOval(ovalROIx , ovalROIy , ovalROIww , ovalROIww );
		//makeRectangle(ROIx , ROIy , ROIwidth , ROIheight );
		//ROIrotateOP ="angle="+i*angleincrement;
		//run("Rotate...", ROIrotateOP );

		getRawStatistics(nPixels, mean);//, min, max, std, histogram);
		totalintA[i] = mean*nPixels;

		if (listresults) setResult("RotationAngle", i, i*angleincrement);
		if (listresults) setResult("totalInt", i, totalintA[i]);

		selectImage(dupID);
		run("Select All"); run("Copy");
		close();
		if (createstack) {
			selectImage(stackID);
			setSlice(i+1);
			run("Paste");
			//print(totalintA[i]);
		}
	}
	setBatchMode("exit and display");
	if (listresults) updateResults();
	maxposition = K_retrunArrayMaxPosition(totalintA);
	rotation = maxposition * angleincrement;
	netrotation = rotation;
	if (rotation>180) netrotation = rotation -180;
	if ((netrotation !=90) && (netrotation !=270)) {
		tangent = tan(netrotation/180*3.1415);
	} else { 
		tangent = NaN;		// vertical, 
	}
	//print(getTitle());
	print("max intensity"+ totalintA[maxposition] + " at rotation angle="+ netrotation +" -" +rotation+" tangent =" + tangent);
	print("velocity = "+tangent + "pixels / frame");		

}

//ver.2. underuse on 081030
// Gaussian fit, and if that does not work, use max point.  
function kymographVelMeasureReturnAngle(origID, angleincrement, centerangle, range, listresults, peakdetectmethod ) {
	getDimensions(ww, hh, channels, slices, frames);

	convop ="text1=[1 0 -1\n2 0 -2\n1 0 -1\n] normalize";		//vertical sobel filter
	//convop ="text1=[3 0 -3\n10 0 -10\n3 0 -3\n] normalize";	//vertical Scharr filter


	rotcanvasww = round(sqrt(pow(ww, 2)+pow(hh,2)) * 1.2);
	
	frames = floor(range*2/angleincrement); 
	angleA = newArray(frames);
	totalintA = newArray(frames);

	canvasop = "width="+rotcanvasww +" height="+rotcanvasww +" position=Center zero";

	//OvalROI
	ovalROIww =ww * 0.85;				//0.95  to exclude ege effect by convolution
 	ovalROIx = rotcanvasww/2 - ovalROIww/2 ;
	ovalROIy = rotcanvasww/2 - ovalROIww/2 ;

	if (listresults) run("Clear Results");

	setBatchMode(true);
	for(i=0; i<frames; i++) {
		selectImage(origID);
		run("Duplicate...", "title=[temp]");
		dupID = getImageID();
		run("Canvas Size...", canvasop);
		angleA[i] = i*angleincrement+(centerangle-range);
		op = "angle="+angleA[i]+" grid=0";	//without interpolation is better
		//op = "angle="+angleA[i]+" grid=0 interpolate";
		run("Arbitrarily...", op);
		run("Convolve...", convop);
		makeOval(ovalROIx , ovalROIy , ovalROIww , ovalROIww );
		getRawStatistics(nPixels, mean);//, min, max, std, histogram);
		totalintA[i] = mean*nPixels;

		if (listresults) setResult("RotationAngle", i, angleA[i]);
		if (listresults) setResult("totalInt", i, totalintA[i]);

		selectImage(dupID);
		close();
	}
	setBatchMode("exit and display");

	if (listresults) updateResults();

	if (peakdetectmethod ==1) {
		maxposition = K_retrunArrayMaxPosition(totalintA);
		rotation = angleA[maxposition];
	} else {
		//by gauss fitting
		Fit.doFit("Gaussian", angleA, totalintA);
		rotation = Fit.p(2);
		if (Fit.rSquared<0.8) {		//if the fitting quality is bad...
			print("R^2 ="+Fit.rSquared+"< 0.8: maxpoint method was used. Angle was "+ rotation );
			maxposition = K_retrunArrayMaxPosition(totalintA);
			rotation = angleA[maxposition];
		}
	}
	return rotation;
}

//Double Step Estimates, First roughly by maxpoints, then gaussian fitting to refine
macro "Measure Velocity from Kymograph: Full Frame "{
	print(getTitle());
	roughestimate = kymographVelMeasureReturnAngle(getImageID(), 10, 180, 180, 0, 1);
	rotation = kymographVelMeasureReturnAngle(getImageID(), 0.2, roughestimate , 50, 1, 2);

	netrotation = rotation ;
	if (rotation>180) netrotation = rotation -180;
	if ((netrotation !=90) && (netrotation !=270)) {
		tangent = tan(netrotation/180*3.1415);
	} else { 
		tangent = NaN;		// vertical, 
	}
	print("angle="+ netrotation +" :" +rotation+" tangent =" + tangent);
	print("velocity = "+tangent + " pixels / frame");	
}

//Double Step Estimates, First roughly by maxpoints, then gaussian fitting to refine
macro "Measure Velocity from Kymograph: ROI "{
	if (selectionType()!=0) exit("need a rectangular ROI");
	getSelectionBounds(x, y, width, height);
	if ((height<30) || (width<30)) exit("rectangular ROI should have a width and height larger than 30");
	run("Copy");

	print(getTitle());
	print("Frame "+y+" to "+(y+height));

	setBatchMode(true);
	newImage("temppart", "8-bit Black", width , height, 1);
	duporgID = getImageID();
	run("Paste");
	origID = getImageID();

	roughestimate = kymographVelMeasureReturnAngle(origID, 10, 180, 180, 0, 1);
	rotation = kymographVelMeasureReturnAngle(origID, 0.2, roughestimate , 50, 1, 2);

	selectImage(duporgID);
	close();
	setBatchMode("exit and display");

	netrotation = rotation ;
	if (rotation>180) netrotation = rotation -180;
	if ((netrotation !=90) && (netrotation !=270)) {
		tangent = tan(netrotation/180*3.1415);
	} else { 
		tangent = NaN;		// vertical, 
	}
	print("angle="+ netrotation +" :" +rotation+" tangent =" + tangent);
	print("velocity = "+tangent + " pixels / frame");	
}

macro "-"{}

//Further possible addition: color coding of speed. 
//creates an image with velocities indicated at corresponding positions
// Double step estimates
macro "Scan Kymograph and Measure - Automatic Multiple Measurements"{		
	getDimensions(imgw, imgh, chs, imgslices, imgframes);
	
	bigimgID = getImageID();
	sampledim = getNumber("ROI size in Pixels?", 60);// 60;
	if ((sampledim<60) || (sampledim>imgw) || (sampledim>imgh)) exit("ROI size should be larger than 60 and less than the image width or height");
	rows = floor(imgh / sampledim);
	cols =  floor(imgw / sampledim);
	iteration = rows * cols;
	setFont("SansSerif", 10);
	setJustification("center");
	newImage("velocity", "8-bit Black", imgw, imgh, 1);
	run("Add...", "value=100");
	velimgID = getImageID();
	
	for(j= 0; j<rows; j++) {
		for(i= 0; i<cols; i++) {
			selectImage(bigimgID);
			makeRectangle(i*sampledim , j*sampledim , sampledim , sampledim);
			run("Copy");
			setBatchMode(true);
			newImage("temppart", "8-bit Black", sampledim , sampledim, 1);	
			duporgID = getImageID();
			run("Paste");
			origID = getImageID();
			roughestimate = kymographVelMeasureReturnAngle(origID, 10, 180, 180, 0, 1);
			rotation = kymographVelMeasureReturnAngle(origID, 0.2, roughestimate , 50, 0, 2);
			selectImage(duporgID);
			close();
			setBatchMode("exit and display");
			netrotation = rotation ;
			if (rotation>180) netrotation = rotation -180;
			if ((netrotation !=90) && (netrotation !=270)) {
				tangent = tan(netrotation/180*3.1415);
			} else { 
				tangent = NaN;		// vertical, 
			}
			velocity = tangent; // pixels / frame
			selectImage(velimgID);
			strop = ""+d2s(velocity, 3); 
			drawString(strop , i*sampledim+sampledim/2, j*sampledim+sampledim/2);
			print(velocity );
		}
	}

}

function K_retrunArrayMaxPosition(aA) {
	aA_max=-50000000; //LIB
	maxpos =0;
	for (k=0;k<aA.length;k++) if (aA_max<aA[k]) {
		aA_max=aA[k];
		maxpos = k;
	}
	return maxpos ;
 }

/* Follwoing macros are for development, so commented out 081030

macro "-"{}

macro "recreate ROI" {
	makeOval(ovalROIx , ovalROIy , ovalROIww , ovalROIww );
}

macro "-"{}

macro "valdation -- rotation sampling" {
	getDimensions(imgw, imgh, chs, imgslices, imgframes);
	orgID = getImageID();
	sampledim = 100;
	increment=10;
	totalrot = 180;
	frames = totalrot / increment;
	roix = imgw/2 - sampledim /2;
	roiy = imgh/2 - sampledim /2;
	newImage("rotstack", "8-bit Black", sampledim , sampledim, frames);
	rotstackID= getImageID();
	for(i=0; i<frames; i++) {
		selectImage(orgID);
		run("Duplicate...", "title=temp");
		op = "angle="+(i*increment) +" grid=0";
		run("Arbitrarily...", op);
		makeRectangle(roix , roiy , sampledim , sampledim);
		run("Select All"); run("Copy");
		close();
		selectImage(rotstackID);
		setSlice(i+1);
		run("Paste");
	}		
}

macro "valdation -- rotation measure"{
	increment=10;
	totalrot = 180;
	frames = totalrot / increment;
		run("Clear Results");
	for(i=0; i<frames; i++) {
		setSlice(i+1);
		roughestimate = kymographVelMeasureReturnAngle(getImageID(), 10, 180, 180, 0, 1);
		rotation = kymographVelMeasureReturnAngle(getImageID(), 0.2, roughestimate , 50, 0, 2);
		//rotation = roughestimate = kymographVelMeasureReturnAngle(getImageID(), 1, 180, 180, 0, 1);

		netrotation = rotation ;
		if (rotation>180) netrotation = rotation -180;
		if ((netrotation !=90) && (netrotation !=270)) {
			tangent = tan(netrotation/180*3.1415);
		} else { 
		tangent = NaN;		// vertical, 
		}
		print("angle="+ netrotation +" :" +rotation+" tangent =" + tangent);
		print("velocity = "+tangent + " pixels / frame");


		setResult("RotationAngle", i, i*increment);
		setResult("DetectedAngle", i, netrotation);
 		updateResults();
	}
}


macro "Drraw stripes" {
	getDimensions(imgw, imgh, chs, imgslices, imgframes);
	spacing  =10;
	for (i = 1; i< imgw;i+=spacing) {
		makeLine(i, 0, i, imgh-1);
		run("Fill");
	}

}

*/


